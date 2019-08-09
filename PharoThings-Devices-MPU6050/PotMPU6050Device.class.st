"
I provide implementation of Gyroscope/Accelerator I2C sensor MPU6050.

The code for initialization and sensors reading is based from example:
	https://howtomechatronics.com/tutorials/arduino/arduino-and-mpu6050-accelerometer-and-gyroscope-tutorial/

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
------
s := (RpiBoard3B current) installDevice: PotMPU6050DeviceNew new.
s readAccelerometerAngleXY.
s readGyroscopeAngleXYZ.
s readRollPitchYaw.
s printRollPitchYaw.
s finishRollPitchYaw.
"
Class {
	#name : #PotMPU6050Device,
	#superclass : #PotI2CDevice,
	#instVars : [
		'accErrorX',
		'accErrorY',
		'gyroErrorX',
		'gyroErrorY',
		'gyroErrorZ',
		'currentTime',
		'gyroAngleX',
		'gyroAngleY',
		'gyroAngleZ',
		'roll',
		'pitch',
		'yaw',
		'readProcess'
	],
	#category : #'PharoThings-Devices-MPU6050'
}

{ #category : #'instance creation' }
PotMPU6050Device class >> defaultI2CAddress [
	^16r68
]

{ #category : #controlling }
PotMPU6050Device >> calculateAccelerometerDistanceA: anAccelerometerScaledA B: anAccelerometerScaledB [
	^ (anAccelerometerScaledA squared + anAccelerometerScaledB squared)
		sqrt
]

{ #category : #controlling }
PotMPU6050Device >> calculateAccelerometerRotationX: anAccelerometerScaledX Y: anAccelerometerScaledY Z: anAccelerometerScaledZ [
	| radiansX radiansY rotationX rotationY |
	radiansX := anAccelerometerScaledY arcTan: (self calculateAccelerometerDistanceA: anAccelerometerScaledX B: anAccelerometerScaledZ).
	radiansY := anAccelerometerScaledX arcTan: (self calculateAccelerometerDistanceA: anAccelerometerScaledY B: anAccelerometerScaledZ) * -1.	
	rotationX := radiansX radiansToDegrees.
	rotationY := radiansY radiansToDegrees.
	"rotationX := rotationX - 0.58." "accErrorX ~(0.58) See the calculateIMUError method function for more details"
	"rotationY := rotationY + 1.58."
	^ { rotationX . rotationY }
]

{ #category : #controlling }
PotMPU6050Device >> calculateGyroscopeRotationX: anGyroscopeScaledX Y: anGyroscopeScaledY Z: anGyroscopeScaledZ [
	|  rotationX rotationY rotationZ previousTime elapsedTime |
	previousTime := currentTime.
	currentTime := Time now asMilliSeconds.
	elapsedTime := (currentTime - previousTime) / 1000. "Divide by 1000 to get seconds"
	rotationX := anGyroscopeScaledX * elapsedTime. "deg/s * s = deg"
	rotationY := anGyroscopeScaledY * elapsedTime.
	rotationZ := anGyroscopeScaledZ * elapsedTime.
	^ { rotationX . rotationY . rotationZ}
]

{ #category : #controlling }
PotMPU6050Device >> calculateIMUError [
	| checkTimes acc accX accY gyro gyroX gyroY gyroZ |
	accX := 0.
	accY := 0.
	gyroX := 0.
	gyroY := 0.
	gyroZ := 0.
	checkTimes := 300.
	checkTimes
		timesRepeat: [ "acc := self readAccelerometerAngleXY.
			accX := accX + acc at: 1.
			accY := accY + acc at: 2."
			gyro := self getGyroscopeScaled.
			gyroX := gyroX + gyro at: 1.
			gyroY := gyroY + gyro at: 2.
			gyroZ := gyroZ + gyro at: 3 ].
	"accErrorX := accX / checkTimes.
	accErrorY := accY / checkTimes."
	gyroErrorX := gyroX / checkTimes.
	gyroErrorY := gyroY / checkTimes.
	gyroErrorZ := gyroZ / checkTimes.
	^ { accErrorX . accErrorY . gyroErrorX . gyroErrorY . gyroErrorZ }
]

{ #category : #initialization }
PotMPU6050Device >> connect [
	super connect.
	self initialize.
	self wakeUpSensor
]

{ #category : #controlling }
PotMPU6050Device >> finishRollPitchYaw [ 
	readProcess terminate
]

{ #category : #controlling }
PotMPU6050Device >> getAccelerometerRawData [
	| accX accY accZ |
	accX := self getRegisters2C: 16r3b.
	accY := self getRegisters2C: 16r3d.
	accZ := self getRegisters2C: 16r3f.
	^ { accX . accY . accZ }
]

{ #category : #controlling }
PotMPU6050Device >> getAccelerometerScaled [
	"For a range of +-2g, we need to divide the raw values by 16384, according to the datasheet"
	| acc accX accY accZ |
	acc := self getAccelerometerRawData.
	accX := ((acc at: 1)/16384) asFloat.
	accY := ((acc at: 2)/16384) asFloat.
	accZ := ((acc at: 3)/16384) asFloat.
	^ { accX . accY . accZ }
]

{ #category : #controlling }
PotMPU6050Device >> getGyroscopeRawData [
	| gyroX gyroY gyroZ |
	gyroX := self getRegisters2C: 16r43.
	gyroY := self getRegisters2C: 16r45.
	gyroZ := self getRegisters2C: 16r47.
	^ { gyroX . gyroY . gyroZ }
]

{ #category : #controlling }
PotMPU6050Device >> getGyroscopeScaled [
	"For a 250deg/s range we have to divide first the raw value by 131.0, according to the datasheet"
	| gyro gyroX gyroY gyroZ |
	gyro := self getGyroscopeRawData.
	gyroX := (gyro at: 1)/131 asFloat round: 6.
	gyroY := (gyro at: 2)/131 asFloat round: 6.
	gyroZ := (gyro at: 3)/131 asFloat round: 6.
	^ { gyroX . gyroY . gyroZ }
]

{ #category : #controlling }
PotMPU6050Device >> getRegisters2C: anHex [
	| value  |
	value := self getRegisters: anHex.
	value >= 16r8000
		ifTrue: [ ^ ((65535 - value) + 1) * -1]
		ifFalse: [^ value ]
]

{ #category : #controlling }
PotMPU6050Device >> getRegisters: anHex [
	| h l value |
	h := i2cConnection read8BitsAt: anHex.
	l := i2cConnection read8BitsAt: anHex + 1.
	(h == 0 & l == 0)
		ifTrue: [ self wakeUpSensor.
			1 milliSeconds wait.
			h := i2cConnection read8BitsAt: anHex.
			l := i2cConnection read8BitsAt: anHex + 1 ].
	value := (h bitShift: 8) + l.
	^ value
]

{ #category : #controlling }
PotMPU6050Device >> getTemperatureRawData [
	^ self getRegisters2C: 16r41
]

{ #category : #initialization }
PotMPU6050Device >> initialize [
	gyroAngleX := 0.
	gyroAngleY := 0.
	gyroAngleZ := 0.
	currentTime := 0.
	pitch := 0.
	roll := 0.
	yaw := 0.
	self calculateIMUError
	
]

{ #category : #controlling }
PotMPU6050Device >> monitorRollPitchYaw [
	| gyro errX errY errZ |
	self initialize.
	gyro := self readGyroscopeAngleXYZ.
	errX := gyro at: 1.
	errY := gyro at: 2.
	errZ := gyro at: 3.
	readProcess := [ [ gyro := self readGyroscopeAngleXYZ.
	pitch := (gyro at: 1) - errX round: 0.
	roll := (gyro at: 2) - errY round: 0.
	yaw := (gyro at: 3) - errZ round: 0 ] repeat ]
		forkNamed: 'MPU6050readProcess'
]

{ #category : #acessing }
PotMPU6050Device >> pitch [
	^ pitch
]

{ #category : #controlling }
PotMPU6050Device >> readAccelerometerAngleXY [
	| acc accAngle accAngleX accAngleY |
	acc := self getAccelerometerScaled.
	accAngle := self calculateAccelerometerRotationX: (acc at:1) Y: (acc at:2) Z: (acc at:3).
	accAngleX := (accAngle at: 1) - accErrorX.
	accAngleY := (accAngle at: 2) - accErrorY.
	^ {accAngleX . accAngleY} 
]

{ #category : #controlling }
PotMPU6050Device >> readGyroscopeAngleXYZ [
	| gyro gyroX gyroY gyroZ gyroAngle|
	gyro := self getGyroscopeScaled.
	"Correct the outputs with the calculated error values"
	gyroX := (gyro at:1) - gyroErrorX. "FIXED. test it... | values hardcoded, need to create methods to correct them auto"
	gyroY := (gyro at:2) - gyroErrorY.
	gyroZ := (gyro at:3) - gyroErrorZ.
	gyroAngle := self calculateGyroscopeRotationX: gyroX Y: gyroY Z: gyroZ.
	gyroAngleX := gyroAngleX + gyroAngle at: 1.
	gyroAngleY := gyroAngleY + gyroAngle at: 2.
	gyroAngleZ := gyroAngleZ + gyroAngle at: 3.
	^ { gyroAngleX . gyroAngleY . gyroAngleZ }
]

{ #category : #controlling }
PotMPU6050Device >> readRollPitchYaw [
	| acc accX accY gyro gyroX gyroY gyroZ |
	acc := self readAccelerometerAngleXY.
	gyro := self readGyroscopeAngleXYZ.
	accX := acc at: 1.
	accY := acc at: 2.
	gyroX := gyro at: 1.
	gyroY := gyro at: 2.
	gyroZ := gyro at: 3.
	"Complementary filter - combine acceleromter and gyro angle values 	"
	roll := 0.96 * gyroX + 0.04 * accX.
  	pitch := 0.96 * gyroY + 0.04 * accY.
	yaw :=  gyroZ.
	^ { roll . pitch . yaw }
]

{ #category : #controlling }
PotMPU6050Device >> readTemperature [
	^ self getTemperatureRawData / 340 + 36.53
]

{ #category : #acessing }
PotMPU6050Device >> roll [
	^ roll
]

{ #category : #controlling }
PotMPU6050Device >> showRollPitchYaw [ 
	| gyro lcd  errX errY errZ|
	lcd := (RpiBoard3B current) installDevice: PotLCD1602DeviceI2C new.
	self initialize.
	gyro := self readGyroscopeAngleXYZ.
	errX := gyro at:1.
	errY := gyro at:2.
	errZ := gyro at:3. 
	readProcess := [ [ gyro := self readGyroscopeAngleXYZ.
	pitch := (( gyro at: 1) - errX )round: 0.
	roll := (( gyro at: 2) - errY ) round: 0.
	yaw := (( gyro at: 3) - errZ )round: 0.
	lcd returnHome.
	lcd showMessage: 'R:', pitch asString,'
P:', roll asString, ' Y:', yaw asString	] repeat ] forkNamed: 'MPU6050readProcess' 
]

{ #category : #controlling }
PotMPU6050Device >> wakeUpSensor [
	i2cConnection write8BitsAt: 16r6b data: 0
]

{ #category : #acessing }
PotMPU6050Device >> yaw [
	^ yaw
]
