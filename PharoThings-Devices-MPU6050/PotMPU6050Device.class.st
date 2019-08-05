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
	"super connect"
	

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
