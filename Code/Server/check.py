import cv2
import numpy as np

from camera import Camera     
from led import Led                                                                                            
from motor import tankMotor
from servo import Servo
from infrared import Infrared
from PID import Incremental_PID
from ultrasonic import Ultrasonic

from time import sleep


class Rover:
    def __init__(self):
        self.clamp_mode = 0

        self.servo = Servo()     # Initialize the servo
        self.motor = tankMotor() # Initialize the motor

        self.led = Led() # Initialize the led

        self.infrared = Infrared()                                            # Initialize the infrared sensor
        self.sonic = Ultrasonic()                                             # Initialize the ultrasonic sensor
        self.camera = Camera(preview_size=(320, 240), stream_size=(320, 240)) # Initialize the camera

        self.pid = Incremental_PID(1, 0, 0.0025)    # PID for distance and position control
        self.color_red = [0, 118, 31, 6, 255, 255]  # HSV range for red ball

    def close(self):
        self.stop()
        sleep(0.5)
        self.let_it_go()
        
        self.led.Blink((0, 0, 255))

        self.servo.setServoStop()
        self.motor.close()

        self.infrared.close()
        self.sonic.close()
        self.camera.stop_stream()
        self.camera.close()      

    def move(self, direction, speed=900):
        if direction == "forward":
            speed = speed
            self.current_col +=1
            
        else:
            speed = -speed
            self.current_col -= 1
        
        self.motor.setMotorModel(speed, speed)
        sleep(3.3)

    def turn(self, direction, speed=1200):
        speed = speed if direction == "left" else -speed

        self.motor.setMotorModel(speed, -speed) 
        sleep(90 * 0.0069)

    def stop(self): 
        self.motor.setMotorModel(0, 0)

    def pick_up(self):
        if self.clamp_mode == 0:
            self.motor.setMotorModel(0, 0)  

            for i in range(140, 90, -1):
                self.servo.setServoAngle('1', i)
                sleep(0.01)
            for i in range(90, 150, 1):
                self.servo.setServoAngle('0', i)
                sleep(0.01)  
            for i in range(90, 140, 1):
                self.servo.setServoAngle('1', i)
                sleep(0.01)

            self.clamp_mode = 1

    def put_down(self):
        if self.clamp_mode == 1:
            self.motor.setMotorModel(0, 0)  
            
            for i in range(140, 90, -1):
                self.servo.setServoAngle('1', i)
                sleep(0.01)
            for i in range(150, 90, -1):
                self.servo.setServoAngle('0', i)
                sleep(0.01)
            for i in range(90, 140, 1):
                self.servo.setServoAngle('1', i)
                sleep(0.01)

            self.clamp_mode = 0

    def let_it_go(self):
        if self.clamp_mode == 1:
            for i in range(150, 90, -1):
                self.servo.setServoAngle('0', i)
                sleep(0.01)

            self.clamp_mode = 0

    def move_outside_grid(self):
        complete = True
        while complete:
            distance = self.sonic.get_distance()
            if distance < 15:
                # wall detected
                self.stop()
                self.let_it_go()
                while distance < 15:
                    self.move("backward")
                    self.turn("right")
                    distance = self.sonic.get_distance()
                
                complete = False
            
    
    
    def auto_mode(self):
        print("Running in autonomous mode...")
        self.led.Blink((0, 255, 0))

        try:
            while True:
                # Capture frame using the Camera class
                frame = self.camera.get_frame()
                
                if frame is None:
                    print("Failed to capture frame. Retrying...")
                    continue

                nparr = np.frombuffer(frame, np.uint8)
                frame_np = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
                
                if self.clamp_mode == 0 and self.detect(frame_np):
                    break
                    
            print("Payload picked up, yay")

            # self.turn("left", speed=1600)
            while True:
                self.led.rainbow()

        except KeyboardInterrupt:
            print("Program interrupted")
            cv2.destroyAllWindows()

    def detect(self, video):
        try:
            # Preprocessing
            gs_frame = cv2.GaussianBlur(video, (5, 5), 0)
            gs_frame = cv2.cvtColor(gs_frame, cv2.COLOR_BGR2HSV)
            gs_frame = cv2.erode(gs_frame, np.ones((5, 5), np.uint8), iterations=1)
            gs_frame = cv2.dilate(gs_frame, np.ones((2, 2), np.uint8), iterations=1)

            # Default to red ball detection
            inRange_hsv = cv2.inRange(gs_frame, tuple(self.color_red[:3]), tuple(self.color_red[3:]))
            
            cv2.waitKey(1) # Allow window to update (fixed typo: waitkey → waitKey)

            # Contour detection
            cnts = cv2.findContours(inRange_hsv.copy(), cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)[-2]
            if not cnts:
                self.stop() # Stop if no ball detected
                return False

            c = max(cnts, key=cv2.contourArea)
            ((x, y), radius) = cv2.minEnclosingCircle(c)
            M = cv2.moments(c)

            # might need to remove this
            if radius <= 15 or M["m00"] <= 0:
                self.stop()
                self.turn("right")
                sleep(0.2)
                self.stop()
                return False

            center = (int(M["m10"] / M["m00"]), int(M["m01"] / M["m00"]))

            D = round(1660 / (2 * radius))      # Distance in cm (adjust for ball size)
            x = self.pid.PID_compute(center[0]) # Target center x = 200 (middle of 0-400)
            d = self.pid.PID_compute(D)         # Target distance = 14 cm (middle of 8-20 cm range for ball)

            # Linear scaling: reduce speed as distance decreases
            cv2.circle(video, center, 3, (255, 0, 0), 5)
            cv2.circle(video, center, int(radius), (0, 255, 0), 2)

            print(f"This is the distance and x values: ({D}, {x})")

            
            D = round(1660 / (2 * radius))  # Distance in cm (adjust for ball size)
            x = self.pid.PID_compute(center[0])  # Target center x = 200 (middle of 0-400)
            d = self.pid.PID_compute(D)  # Target distance = 14 cm (middle of 8-20 cm range for ball)


            if d < 9:    # Too close (negative PID indicates error below target)
                self.move("backward") 
            elif d > 12: # Too far (positive PID indicates error above target)
                self.move("forward") 
            else:        # In range (approximately 8-20 cm)
                if x < 85:     # Ball to the left
                    self.turn("left")
                elif x > 315:  # Ball to the right
                    self.turn("right")
                else:          # Centered and in range: Pick up red ball
                    self.stop() 
                    self.pick_up()
                    self.move_outside_grid()
                    cv2.destroyAllWindows() 
                    return True
            
        except Exception as e:
            print(f"Error in block_detect: {e}")


if __name__ == '__main__':
    rover = Rover()

    # rover.explore_grid()
    rover.auto_mode()


