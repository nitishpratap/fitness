//
//  gfunction.swift
//  WatFitProt
//
//  Created by   Nitish Pratap Yadav
//    
//

import Foundation
import CoreMotion
import AVFoundation
import UIKit

class gfunction{
    var lastRepGood = 0 //bad
    var isbad = 0
    var quantity = 0
    var goodQuality = 0
    var badQuality = 0
    var exercise = Exercise()
    var motionStatus = 0
    var syncGroup: DispatchGroup?
   // var syncGroup2: DispatchGroup?
    var timer = Timer()
    @IBOutlet weak var progressImg: UIImageView!
    @IBOutlet weak var currentReps: UILabel!
    @IBOutlet weak var startTicker: UILabel!

    var motion = CMMotionManager()
    var x_buffer = [Double]()
    var y_buffer = [Double]()
    var z_buffer = [Double]()
    let buffersize = 15
    var buffed = 0
    
    var x = Double()
    var y = Double()
    var z = Double()
    var staticUpper = Double()
    var StaticLower = Double()
    var goodActionUpper = Double()
    var goodResetLower = Double()
    
    var filteredBuffer_x = [Int]()
    var filteredBuffer_y = [Int]()
    var filteredBuffer_z = [Int]()
    
    var filtedBufferSize = 15
    
    var formConstrainRoll = Double()
    var formConstrainPitch = Double()
    var formConstrainYaw = Double()
    
    //audio players
    var goodRepPlayer = AVAudioPlayer()
    var badRepPlayer = AVAudioPlayer()
    
    func setUpdateInterval(time:Double){
        motion.deviceMotionUpdateInterval = time
        //print("interval time is ", time)
    }
    
    func setGoodImage(){
        progressImg.loadGif(name: "source")
        isbad = 0
    }
    func setBadImage(){
        progressImg.loadGif(name: "bad")
        isbad = 1
    }
    func startRecord(){
        syncGroup?.enter()
        print("exercise in gfunction: ", exercise.name ?? "Y")
        motion.startDeviceMotionUpdates(to: OperationQueue.current!, withHandler: {
            (deviceMotion, error) -> Void in
            //print("deviceMotion: ", deviceMotion?.userAcceleration)
            if(error == nil) {
                self.handleDeviceMotionUpdate(deviceMotion: deviceMotion!)
            } else {
                //handle the error
            }
        })
    }
    
    
    func degrees(radians:Double) -> Double {
        return 180 / M_PI * radians
    }
    
    @objc func updateTimer(){
        timer.invalidate()
        self.motion.stopDeviceMotionUpdates()

        self.startTicker.text = "Finished"
        
          self.syncGroup?.leave()
    }
    
    func playBadSound(){
       // syncGroup2?.enter()
        if quantity > 1 {
            if(badRepPlayer.isPlaying){
                badRepPlayer.currentTime = 0
                // badRepPlayer.play()
            }
            else{
                badRepPlayer.play()
            }
            
        }else{
            lastRepGood = 0
        }
        //syncGroup2?.leave()
        return
    }
    
    func playGoodSound(){
        // syncGroup2?.enter()
        if quantity > 1 {
            if(goodRepPlayer.isPlaying){
                goodRepPlayer.currentTime = 0
                // badRepPlayer.play()
            }
            else{
                goodRepPlayer.play()
            }
            
        }else{
            lastRepGood = 1
        }
        //syncGroup2?.leave()
        return
    }
    
    
    func handleDeviceMotionUpdate(deviceMotion:CMDeviceMotion) {
        var attitude = deviceMotion.attitude
        var roll = degrees(radians: attitude.roll)
        var pitch = degrees(radians: attitude.pitch)
        var yaw = degrees(radians: attitude.yaw)
        //print( " Roll: ",roll, " Pitch: ", pitch, " Yaw: ", yaw)
        
        if pitch < formConstrainPitch {
            if isbad == 0 {
                setBadImage()
                playBadSound()
            }
            print("bad form")
        }
        
        var accelerate = deviceMotion.userAcceleration
        let roundigit = 10000.0
        var x = round(accelerate.x * roundigit)/roundigit
        var y = round(accelerate.y * roundigit)/roundigit
        var z = round(accelerate.z * roundigit)/roundigit
        //print("x: ", x, " y:", y, " z:", z)
        if x_buffer.count >= buffersize {
            x_buffer.remove(at: 0)
            y_buffer.remove(at: 0)
            z_buffer.remove(at: 0)
        }
        
        x_buffer.append(x)
        y_buffer.append(y)
        z_buffer.append(z)
        
        
        //smoothing algorithm**************************************************
        //start exercise*******************************************************
        if x_buffer.count >= buffersize {
            x = smoothing(buffname:"x")
            y = smoothing(buffname:"y")
            z = smoothing(buffname:"z")
            
            x = round(x * roundigit)/roundigit
            y = round(y * roundigit)/roundigit
            z = round(z * roundigit)/roundigit
            //print("Strat Exercise")
            buffed = 1
        }
        //********************************************************************
        //evaluatingCurrentGforce(g:y)
        
        
        //evaluating Y status ***************************************
        if buffed ==  1 {
            if filteredBuffer_y.count >= filtedBufferSize {
                filteredBuffer_y.remove(at: 0)
            }
            
            filteredBuffer_y.append(evaluatingCurrentGforce(g:y))
            
            if filteredBuffer_y.count ==  filtedBufferSize {
                checkMotionStatus()
            }
            
        }
        //********************************************************************
        //print("x: ", x, " y:", y, " z:", z)
        
        if quantity <= 0 {
            //self.timer = Timer.scheduledTimer(timeInterval: 2, target: self,   selector: (#selector(self.updateTimer)), userInfo: nil, repeats: true)
            
            
            timer.invalidate()
            self.motion.stopDeviceMotionUpdates()
            
            self.startTicker.text = "Finished"
            
            self.syncGroup?.leave()
           // syncGroup2?.notify(queue: .main){
               // self.setUpdateInterval(time: 1)
            
              //  self.timer = Timer.scheduledTimer(timeInterval: 3, target: self,   selector: (#selector(self.updateTimer)), userInfo: nil, repeats: true)
                print("gyro stopped")
            
            //
           // }
            
           // return
        }
        
        
        
    }
    
    func evaluatingCurrentGforce(g:Double) -> Int{
        
        if g > goodActionUpper {
            print ("bad rising pace :", g)
            if isbad == 0 {
                setBadImage()
            }
            badQuality = badQuality + 1
            return 1
        }
        
        if g > staticUpper && g < goodActionUpper {
            //    print ("good rising pace :", g)
            return 1
        }
        
        
        if g < staticUpper && g > StaticLower {
            //    print ("static y:", g)
            return 0
        }
        
        if g > goodResetLower && g < StaticLower {
            //  print ("good falling pace :", g)
            return -1
        }
        
        if g < goodResetLower {
            print ("bad falling pace :", g)
            if isbad == 0 {
                setBadImage()
            }
            badQuality = badQuality + 1
            return -1
        }
        
        return 100
        
    }
    
    
    
    
    func checkMotionStatus() {
        if motionStatus == 0 && goThroughfiltedBufferY(target: -1) == 1{
            motionStatus = 1
            print("Start moving up ************************************")
            clearBufferY()
            return
        }
        if motionStatus == 1 && goThroughfiltedBufferY(target: 1) == 1{
            motionStatus = 2
            print("end moving up ************************************")
            clearBufferY()
            return
        }
        if motionStatus == 2 && goThroughfiltedBufferY(target: 0) == 1{
            motionStatus = 3
            print("break in the middle ************************************")
            clearBufferY()
            return
        } else if motionStatus == 2 && goThroughfiltedBufferY(target: 1) == 1{
            motionStatus = 3
            print("start moving down without break ************************************")
            //badQuality = badQuality + 1
            clearBufferY()
            return
        }
        
        if motionStatus == 3 && goThroughfiltedBufferY(target: 1) == 1{
            motionStatus = 4
            print("start moving down ************************************")
            clearBufferY()
            return
        }
        
        if motionStatus == 4 && goThroughfiltedBufferY(target: -1) == 1 {
            motionStatus = 5
            print("end moving down ************************************")
            clearBufferY()
            return
        }
        
        
        if motionStatus == 5 && goThroughfiltedBufferY(target: 0) == 1 {
            motionStatus = 0
            print("rep finished. ************************************")
            clearBufferY()
            exercise.incrementOverallReps()
            if badQuality == 0{
                goodQuality = goodQuality + 1
                setGoodImage()
                //play goodrepsound
   //*************************************************
                playGoodSound()
                
    //*************************************************
                exercise.incrementGoodReps()
                
            }
     //*************************************************
            else{
                //play badrepsound
            
//                if(badRepPlayer.isPlaying){
//                    badRepPlayer.currentTime = 0
//                   // badRepPlayer.play()
//                }
//                else{
//                    badRepPlayer.play()
//                }
                
                playBadSound()

            }
            quantity = quantity - 1
            currentReps.text = String(exercise.reps! - quantity)
     //*************************************************
            print("Quantity: ", quantity, " Good Quality: ", goodQuality, " ************************************!!!!!!!!")
            badQuality = 0
            
            return
            
        }  else if motionStatus == 5 && goThroughfiltedBufferY(target: -1) == 1 {
            motionStatus = 1
            exercise.incrementOverallReps()
            
            if badQuality == 0{
                goodQuality = goodQuality + 1
                setGoodImage()
                
         //*************************************************
                playGoodSound()
         //*************************************************
                exercise.incrementGoodReps()
            }
         //*************************************************
            else{
                //play badrepsound
                playBadSound()

            }
            
         //*************************************************
            clearBufferY()
            print("rep finished without rest. ************************************")
            quantity = quantity - 1
            currentReps.text = String(exercise.reps! - quantity)
            print("Quantity: ", quantity, " Good Quality: ", goodQuality, " ************************************")
            badQuality = 0
            return
        }
        
        
    }
    
    func clearBufferY(){
        for i in stride(from: 0, to: filtedBufferSize, by: 1){
            filteredBuffer_y[i] = 100
        }
        //filteredBuffer_y[filtedBufferSize - 1] = 100
    }
    
    func goThroughfiltedBufferY(target: Int) -> Int{
        for i in stride(from: 0, to: filtedBufferSize, by: 1){
            if target != filteredBuffer_y[i]{
                return 0
            }
        }
        return 1
    }
    
    
    func smoothing (buffname: Character) -> Double {
        
        if buffname == "x" {
            var sum = 0.0
            for xx in x_buffer{
                sum = sum + xx
            }
            return sum/Double(x_buffer.count)
            
        }else if buffname == "y" {
            var sum = 0.0
            for xx in y_buffer{
                sum = sum + xx
            }
            return sum/Double(y_buffer.count)
            
        }else if buffname == "z" {
            var sum = 0.0
            for xx in z_buffer{
                sum = sum + xx
            }
            return sum/Double(z_buffer.count)
            
        }else{
            return 0.0
        }
        
    }
    
}
