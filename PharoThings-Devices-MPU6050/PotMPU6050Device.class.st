"
I provide implementation of Gyroscope/Accelerator I2C sensor MPU6050.

The code for initialization and sensors reading is based from example:
	https://tutorials-raspberrypi.com/measuring-rotation-and-acceleration-raspberry-pi/

Register map:
	https://www.i2cdevlib.com/devices/mpu6050#registers

To use it: 
sensor := (RpiBoard3B current) installDevice: PotMPU6050Device new.
or on inspector:
sensor := board installDevice: PotMPU6050Device new.

API:
readGyroscope. ""#(1540 -9 -211)""
readGyroscopeSkaliert. ""#(13.526718 -1.916031 -1.526718)""
readAccelerometer. ""#(748 -892 15676)""
readAccelerometerSkaliert. ""#(0.033691 -0.051025 0.974121)""
readRotationXY. ""#(-3.224775339993247 -2.4755961852044157)""

sensor := (RpiBoard3B current) installDevice: PotMPU6050Device new.
sensor readRollPitchYaw
sensor printRollPitchYaw.
sensor finishRollPitchYaw.
"
Class {
	#name : #PotMPU6050Device,
	#superclass : #PotI2CDevice,
	#instVars : [
		'readProcess'
	],
	#category : #'PharoThings-Devices-MPU6050'
}

{ #category : #'instance creation' }
PotMPU6050Device class >> defaultI2CAddress [
	^16r68
]

{ #category : #controlling }
PotMPU6050Device >> calculateDistanceA: anAccelerometerScaledA B: anAccelerometerScaledB [
	^ ((anAccelerometerScaledA*anAccelerometerScaledA)+(anAccelerometerScaledB*anAccelerometerScaledB)) sqrt
]

{ #category : #controlling }
PotMPU6050Device >> calculateRotationX: anAccelerometerScaledX Y: anAccelerometerScaledY Z: anAccelerometerScaledZ [
	| radiansX radiansY rotationX rotationY |
	radiansX := anAccelerometerScaledY arcTan: (self calculateDistanceA: anAccelerometerScaledX B: anAccelerometerScaledZ).
	radiansY := anAccelerometerScaledX arcTan: (self calculateDistanceA: anAccelerometerScaledY B: anAccelerometerScaledZ).	
	rotationX := radiansX radiansToDegrees.
	rotationY := radiansY radiansToDegrees * -1.
	^ { rotationX . rotationY }
]

{ #category : #controlling }
PotMPU6050Device >> connect [
	super connect.
	self wakeUpSensor 
	

]

{ #category : #controlling }
PotMPU6050Device >> finishRollPitchYaw [
	readProcess terminate
]

{ #category : #controlling }
PotMPU6050Device >> printRollPitchYaw [
	| gyroscopeAngles pitch roll yaw  lcd |
	lcd := (RpiBoard3B current) installDevice: PotLCD1602DeviceI2C new.
	pitch := 0. roll := 0. yaw := 0.
	readProcess := [ [ gyroscopeAngles := self readRollPitchYaw.
	pitch := (pitch + gyroscopeAngles at: 1) round: 2.
	roll := (roll + gyroscopeAngles at: 2) round: 2.
	yaw := (yaw + gyroscopeAngles at: 3) round: 2.
	lcd returnHome.
	lcd showMessage: 'x:', pitch asString,'
y:', roll asString, ' z:', yaw asString] repeat ] forkNamed: 'readProcess'
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
PotMPU6050Device >> readAccelerometerScaled [
	| acc accX accY accZ |
	acc := self readAccelerometer.
	accX := ((acc at: 1)/16384) asFloat round: 6.
	accY := ((acc at: 2)/16384) asFloat round: 6.
	accZ := ((acc at: 3)/16384) asFloat round: 6.
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
PotMPU6050Device >> readGyroscopeScaled [
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
	(h == 0 & l == 0)
		ifTrue: [ self wakeUpSensor. 1 milliSeconds wait.
			h := i2cConnection read8BitsAt: anHex.
			l := i2cConnection read8BitsAt: anHex + 1 ].
	value := (h bitShift: 8) + l.
	^ value
]

{ #category : #controlling }
PotMPU6050Device >> readRollPitchYaw [
	| gyroscope pitch roll yaw timer timeStep |
	timeStep := 0.01.
	timer := Time now asMilliSeconds.
	gyroscope := self readGyroscope.
	roll := (gyroscope at: 1) * timeStep.
	pitch := (gyroscope at: 2) * timeStep.
	yaw := (gyroscope at: 3) * timeStep.
	(Time now asMilliSeconds - timer) milliSeconds wait.
	^ { yaw . pitch . roll }
]

{ #category : #controlling }
PotMPU6050Device >> readRotationXY [
	| accelerometerScaled rotation rotationX rotationY |
	accelerometerScaled := self readAccelerometerScaled.
	rotation := self calculateRotationX: (accelerometerScaled at: 1) Y: (accelerometerScaled at: 2) Z: (accelerometerScaled at: 3).
	rotationX := rotation at: 1.
	rotationY := rotation at: 2.
	^ { rotationX . rotationY }
]

{ #category : #controlling }
PotMPU6050Device >> wakeUpSensor [
	i2cConnection write8BitsAt: 16r6b data: 0
]
