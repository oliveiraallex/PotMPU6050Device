Class {
	#name : #PotMPU6050Connect,
	#superclass : #PotMPU6050Device,
	#instVars : [
		'readProcess'
	],
	#category : #'PharoThings-Devices-MPU6050'
}

{ #category : #accessing }
PotMPU6050Connect class >> get [
	^ self allInstances first
]

{ #category : #accessing }
PotMPU6050Connect class >> init [
	self allSubInstances isEmpty 
		ifTrue: [ ^ (RpiBoard3B current installDevice: self new) ]
		ifFalse: [ ^ self allInstances first ]
]
