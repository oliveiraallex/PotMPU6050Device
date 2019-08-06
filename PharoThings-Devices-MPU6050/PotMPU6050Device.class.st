"
I provide implementation of Gyroscope / Accelerator sensor MPU6050.

The code for initialization and sensors reading is copied from sunfolder example:

	https://tutorials-raspberrypi.com/measuring-rotation-and-acceleration-raspberry-pi/

Register map:

	https://www.i2cdevlib.com/devices/mpu6050#registers
"
Class {
	#name : #PotMPU6050Device,
	#superclass : #PotI2CDevice,
	#category : #'PharoThings-Devices-MPU6050'
}

{ #category : #'instance creation' }
PotMPU6050Device class >> defaultI2CAddress [
	^16r68
]

{ #category : #controlling }
PotMPU6050Device >> connect [
	super connect
	

]

{ #category : #controlling }
PotMPU6050Device >> readAccelerometer [
	| accX accY accZ |
	accX := self readRegisters2C: 16r3b.
	accY := self readRegisters2C: 16r3d.
	accZ := self readRegisters2C: 16r3f.
	^ { accX . accY . accZ }
]

{ #category : #controlling }
PotMPU6050Device >> readAccelerometerSkaliert [
	| acc accX accY accZ |
	acc := self readGyroscope.
	accX := (acc at: 1)/16384 asFloat round: 6.
	accY := (acc at: 2)/16384 asFloat round: 6.
	accZ := (acc at: 3)/16384 asFloat round: 6.
	^ { accX . accY . accZ }
]

{ #category : #controlling }
PotMPU6050Device >> readGyroscope [
	| gyroX gyroY gyroZ |
	gyroX := self readRegisters2C: 16r43.
	gyroY := self readRegisters2C: 16r45.
	gyroZ := self readRegisters2C: 16r47.
	^ { gyroX . gyroY . gyroZ }
]

{ #category : #controlling }
PotMPU6050Device >> readGyroscopeSkaliert [
	| gyro gyroX gyroY gyroZ |
	gyro := self readGyroscope.
	gyroX := (gyro at: 1)/131 asFloat round: 6.
	gyroY := (gyro at: 2)/131 asFloat round: 6.
	gyroZ := (gyro at: 3)/131 asFloat round: 6.
	^ { gyroX . gyroY . gyroZ }
]

{ #category : #controlling }
PotMPU6050Device >> readRegisters2C: anHex [
	| value  |
	value := self readRegisters: anHex.
	value >= 16r8000
		ifTrue: [ ^ ((65535 - value) + 1) * -1]
		ifFalse: [^ value ]
]

{ #category : #controlling }
PotMPU6050Device >> readRegisters: anHex [
	| h l value |
	h := i2cConnection read8BitsAt: anHex.
	l := i2cConnection read8BitsAt: anHex + 1.
	value := (h bitShift: 8) + l.
	^ value
]
