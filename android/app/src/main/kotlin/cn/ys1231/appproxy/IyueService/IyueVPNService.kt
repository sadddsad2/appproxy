package cn.ys1231.appproxy.IyueService

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.net.VpnService
import android.os.Binder
import android.os.Build
import android.os.IBinder
import android.os.ParcelFileDescriptor
import android.util.Log
import androidx.core.app.NotificationCompat
import cn.ys1231.appproxy.MainActivity
import cn.ys1231.appproxy.R
import com.google.gson.Gson
import engine.Engine
import engine.Key
// 导入 echproxy
import echproxy.Echproxy
import echproxy.Config as EchConfig

class IyueVPNService : VpnService() {

    private val TAG = "iyue->${this.javaClass.simpleName}"

    private var vpnInterface: ParcelFileDescriptor? = null
    private var isRunning = false
    private val binder = VPNServiceBinder()
    
    // echproxy 服务器实例
    private var echproxyServer: echproxy.Server? = null

    inner class VPNServiceBinder : Binder() {
        fun getService(): IyueVPNService = this@IyueVPNService
    }

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "onCreate: VPNServiceBinder")

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channelId = "iyue_vpn_channel"
            val channelName = "Iyue VPN"
            val importance = NotificationManager.IMPORTANCE_DEFAULT
            val channel = NotificationChannel(channelId, channelName, importance).apply {
                description = "Iyue VPN Service Channel"
                lightColor = Color.BLUE
                lockscreenVisibility = Notification.VISIBILITY_PRIVATE
            }
            val notificationManager: NotificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    override fun onBind(intent: Intent?): IBinder {
        Log.d(TAG, "onBind: VPNServiceBinder")
        return binder
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "onStartCommand: ${intent.toString()}")
        return START_NOT_STICKY
    }

    fun startVpnService(data: Map<String, Any>) {
        Log.d(TAG, "startVpnService: $data")

        val proxyName = data["proxyName"].toString()
        val serverAddr = data["serverAddr"].toString()
        val listenAddr = (data["listenAddr"] as? String) ?: "127.0.0.1:1080"
        val preferredIP = (data["preferredIP"] as? String) ?: ""
        val token = (data["token"] as? String) ?: ""
        val dnsServer = (data["dnsServer"] as? String) ?: "https://1.1.1.1/dns-query"
        val echDomain = (data["echDomain"] as? String) ?: "cloudflare-ech.com"

        try {
            // 1. 启动 echproxy 本地 SOCKS5 服务
            val echConfig = EchConfig()
            echConfig.listenAddr = listenAddr
            echConfig.serverAddr = serverAddr
            
            // 如果有优选IP，使用优选IP替换域名
            if (preferredIP.isNotEmpty()) {
                echConfig.serverIP = preferredIP
                Log.d(TAG, "使用优选IP: $preferredIP")
            } else {
                Log.d(TAG, "使用DNS自动解析")
            }
            
            echConfig.token = token
            echConfig.dnsServer = dnsServer
            echConfig.echDomain = echDomain

            echproxyServer = Echproxy.newServer(echConfig)
            echproxyServer?.start()
            
            Log.d(TAG, "========== echproxy 配置 ==========")
            Log.d(TAG, "  本地监听: $listenAddr")
            Log.d(TAG, "  Workers: $serverAddr")
            if (preferredIP.isNotEmpty()) {
                Log.d(TAG, "  优选IP: $preferredIP")
            } else {
                Log.d(TAG, "  解析方式: DNS自动解析")
            }
            Log.d(TAG, "  DNS服务器: $dnsServer")
            Log.d(TAG, "  ECH域名: $echDomain")
            if (token.isNotEmpty()) {
                Log.d(TAG, "  认证Token: ${token.take(8)}...")
            }
            Log.d(TAG, "===================================")

        } catch (e: Exception) {
            Log.e(TAG, "echproxy 启动失败: ${e.message}")
            e.printStackTrace()
            return
        }

        // 2. 创建前台通知
        val notificationIntent = Intent(this, MainActivity::class.java)
            .putExtra("iyue_vpn_channel", true)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            notificationIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // 通知内容
        val notificationText = if (preferredIP.isNotEmpty()) {
            "Workers: $serverAddr\n优选IP: $preferredIP"
        } else {
            "Workers: $serverAddr"
        }

        val notification = NotificationCompat.Builder(this, "iyue_vpn_channel")
            .setContentTitle("${applicationInfo.loadLabel(packageManager)}: $proxyName")
            .setContentText(notificationText)
            .setStyle(NotificationCompat.BigTextStyle().bigText(notificationText))
            .setSmallIcon(R.mipmap.vpn, 3)
            .setContentIntent(pendingIntent)
            .build()

        startForeground(1, notification)

        // 3. 配置 VPN 接口
        val builder = Builder()
            .addAddress("10.0.0.2", 24)
            .addRoute("0.0.0.0", 0)
            .setMtu(1500)
            .setSession(packageName)

        val allowedApps = jsonToList(data["appProxyPackageList"].toString())
        if (allowedApps.isEmpty()) {
            builder.addDisallowedApplication(packageName)
        } else {
            for (appPackageName in allowedApps) {
                try {
                    Log.d(TAG, "addAllowedApplication: $appPackageName")
                    builder.addAllowedApplication(appPackageName)
                } catch (e: Exception) {
                    Log.e(TAG, "addAllowedApplication: ${e.message}")
                }
            }
        }

        try {
            vpnInterface = builder.establish()
            if (vpnInterface == null) {
                Log.e(TAG, "vpnInterface: create establish error")
                stopEchproxy()
                return
            }

            // 4. 配置 tun2socks 连接到本地 echproxy
            val key = Key()
            key.mark = 0
            key.mtu = 1500
            key.device = "fd://" + vpnInterface!!.fd
            key.setInterface("")
            key.logLevel = "error"
            key.proxy = "socks5://$listenAddr"  // 使用配置的监听地址
            key.restAPI = ""
            key.tcpSendBufferSize = ""
            key.tcpReceiveBufferSize = ""
            key.tcpModerateReceiveBuffer = false
            
            Engine.insert(key)
            Engine.start()
            
            Log.d(TAG, "tun2socks 已启动，代理: ${key.proxy}")
            isRunning = true

        } catch (e: Exception) {
            Log.e(TAG, "startEngine error: ${e.message}")
            e.printStackTrace()
            stopEchproxy()
        }
    }

    fun stopVpnService() {
        Log.d(TAG, "stopVpnService: vpnInterface $vpnInterface")
        try {
            if (vpnInterface != null) {
                vpnInterface?.close()
                vpnInterface = null
                isRunning = false
                
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    stopForeground(STOP_FOREGROUND_REMOVE)
                }
            }
            
            // 停止 echproxy
            stopEchproxy()
            
            Log.d(TAG, "stopVpnService: success")
        } catch (e: Exception) {
            Log.e(TAG, "stopVpnService: ${e.message}")
        }
    }

    private fun stopEchproxy() {
        try {
            echproxyServer?.stop()
            echproxyServer = null
            Log.d(TAG, "echproxy 已停止")
        } catch (e: Exception) {
            Log.e(TAG, "停止 echproxy 失败: ${e.message}")
        }
    }

    fun isRunning(): Boolean {
        return isRunning
    }

    private fun jsonToList(jsonString: String): List<String> {
        val gson = Gson()
        return try {
            gson.fromJson(jsonString, Array<String>::class.java).toList()
        } catch (e: Exception) {
            Log.e(TAG, "解析应用列表失败: ${e.message}")
            emptyList()
        }
    }

    override fun onUnbind(intent: Intent?): Boolean {
        Log.d(TAG, "onUnbind: IyueVPNService")
        stopVpnService()
        return super.onUnbind(intent)
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "onDestroy: IyueVPNService")
    }
}