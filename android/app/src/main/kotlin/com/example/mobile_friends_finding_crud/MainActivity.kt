package com.example.mobile_friends_finding_crud


import android.Manifest
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationManager
import android.os.Looper
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.google.android.gms.location.*
import com.google.gson.Gson
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import android.telephony.SmsManager

class MainActivity : FlutterActivity() {
    private val channel = "app/native-code"
    private val eventChannel = "app/native-code-event"
    private val LOCATION_PERMISSION_REQUEST_CODE = 103
    private val SMS_PERMISSIONS_REQUEST_CODE = 101
    
    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private lateinit var eventSink: EventChannel.EventSink
    private lateinit var smsReceiver: BroadcastReceiver

    // SMS message templates
    private val LOCATION_REQUEST_PREFIX = "LOCATION_REQUEST:"
    private val LOCATION_RESPONSE_PREFIX = "LOCATION_RESPONSE:"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestLocation" -> {
                    val phoneNumber = call.argument<String>("phoneNumber") ?: ""
                    sendLocationRequest(phoneNumber, result)
                }
                "getCurrentLocation" -> {
                    getCurrentLocation(result)
                }
                "sendLocationResponse" -> {
                    val phoneNumber = call.argument<String>("phoneNumber") ?: ""
                    val latitude = call.argument<Double>("latitude") ?: 0.0
                    val longitude = call.argument<Double>("longitude") ?: 0.0
                    sendLocationResponse(phoneNumber, latitude, longitude, result)
                }
                else -> result.notImplemented()
            }
        }

        // Set up event channel for incoming SMS
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, eventChannel).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events ?: return
                    registerSmsReceiver()
                }

                override fun onCancel(arguments: Any?) {
                    unregisterReceiver(smsReceiver)
                }
            }
        )
    }

    private fun sendLocationRequest(phoneNumber: String, result: MethodChannel.Result) {
        if (checkSmsPermission()) {
            try {
                val smsManager = SmsManager.getDefault()
                smsManager.sendTextMessage(
                    phoneNumber,
                    null,
                    "$LOCATION_REQUEST_PREFIX${System.currentTimeMillis()}",
                    null,
                    null
                )
                result.success("Location request sent")
            } catch (e: Exception) {
                result.error("SMS_ERROR", "Failed to send location request", e.message)
            }
        } else {
            requestSmsPermission()
            result.error("PERMISSION_DENIED", "SMS permission not granted", null)
        }
    }

    private fun sendLocationResponse(phoneNumber: String, latitude: Double, longitude: Double, result: MethodChannel.Result) {
        if (checkSmsPermission()) {
            try {
                val locationMessage = "$LOCATION_RESPONSE_PREFIX$latitude,$longitude"
                val smsManager = SmsManager.getDefault()
                smsManager.sendTextMessage(phoneNumber, null, locationMessage, null, null)
                result.success("Location response sent")
            } catch (e: Exception) {
                result.error("SMS_ERROR", "Failed to send location response", e.message)
            }
        } else {
            requestSmsPermission()
            result.error("PERMISSION_DENIED", "SMS permission not granted", null)
        }
    }

    private fun getCurrentLocation(result: MethodChannel.Result) {
        if (checkLocationPermission()) {
            fusedLocationClient.lastLocation
                .addOnSuccessListener { location ->
                    if (location != null) {
                        val locationMap = mapOf(
                            "latitude" to location.latitude,
                            "longitude" to location.longitude
                        )
                        result.success(locationMap)
                    } else {
                        requestLocationUpdate(result)
                    }
                }
                .addOnFailureListener { e ->
                    result.error("LOCATION_ERROR", "Failed to get location", e.message)
                }
        } else {
            requestLocationPermission()
            result.error("PERMISSION_DENIED", "Location permission not granted", null)
        }
    }

    private fun requestLocationUpdate(result: MethodChannel.Result) {
        val locationRequest = LocationRequest.create().apply {
            priority = LocationRequest.PRIORITY_HIGH_ACCURACY
            interval = 0
        }

        val locationCallback = object : LocationCallback() {
            override fun onLocationResult(locationResult: LocationResult) {
                locationResult.lastLocation?.let { location ->
                    val locationMap = mapOf(
                        "latitude" to location.latitude,
                        "longitude" to location.longitude
                    )
                    result.success(locationMap)
                    fusedLocationClient.removeLocationUpdates(this)
                }
            }
        }

        if (checkLocationPermission()) {
            fusedLocationClient.requestLocationUpdates(
                locationRequest,
                locationCallback,
                Looper.getMainLooper()
            )
        }
    }

    private fun registerSmsReceiver() {
        smsReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                if (intent?.action == "android.provider.Telephony.SMS_RECEIVED") {
                    val bundle = intent.extras
                    if (bundle != null) {
                        val pdus = bundle["pdus"] as Array<*>
                        for (pdu in pdus) {
                            val smsMessage = android.telephony.SmsMessage.createFromPdu(pdu as ByteArray)
                            val message = smsMessage.messageBody
                            val sender = smsMessage.originatingAddress

                            when {
                                message.startsWith(LOCATION_REQUEST_PREFIX) -> {
                                    handleLocationRequest(sender ?: "")
                                }
                                message.startsWith(LOCATION_RESPONSE_PREFIX) -> {
                                    handleLocationResponse(sender ?: "", message)
                                }
                            }
                        }
                    }
                }
            }
        }
        registerReceiver(smsReceiver, IntentFilter("android.provider.Telephony.SMS_RECEIVED"))
    }

    private fun handleLocationRequest(sender: String) {
        if (checkLocationPermission()) {
            getCurrentLocation(object : MethodChannel.Result {
                override fun success(result: Any?) {
                    @Suppress("UNCHECKED_CAST")
                    val locationMap = result as? Map<String, Double>
                    if (locationMap != null) {
                        sendLocationResponse(
                            sender,
                            locationMap["latitude"] ?: 0.0,
                            locationMap["longitude"] ?: 0.0,
                            object : MethodChannel.Result {
                                override fun success(result: Any?) {}
                                override fun error(code: String, message: String?, details: Any?) {}
                                override fun notImplemented() {}
                            }
                        )
                    }
                }
                override fun error(code: String, message: String?, details: Any?) {}
                override fun notImplemented() {}
            })
        }
    }

    private fun handleLocationResponse(sender: String, message: String) {
        try {
            val locationPart = message.removePrefix(LOCATION_RESPONSE_PREFIX)
            val (latitude, longitude) = locationPart.split(",").map { it.toDouble() }
            val locationData = mapOf(
                "sender" to sender,
                "latitude" to latitude,
                "longitude" to longitude
            )
            eventSink.success(Gson().toJson(locationData))
        } catch (e: Exception) {
            eventSink.error("PARSE_ERROR", "Failed to parse location response", e.message)
        }
    }

    private fun checkSmsPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.SEND_SMS
        ) == PackageManager.PERMISSION_GRANTED &&
                ContextCompat.checkSelfPermission(
                    this,
                    Manifest.permission.RECEIVE_SMS
                ) == PackageManager.PERMISSION_GRANTED
    }

    private fun checkLocationPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun requestSmsPermission() {
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.SEND_SMS, Manifest.permission.RECEIVE_SMS),
            SMS_PERMISSIONS_REQUEST_CODE
        )
    }

    private fun requestLocationPermission() {
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.ACCESS_FINE_LOCATION),
            LOCATION_PERMISSION_REQUEST_CODE
        )
    }
}