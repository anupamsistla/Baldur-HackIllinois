import cv2
import numpy as np
from camera import Camera                                                                                                 
from motor import tankMotor
from servo import Servo
from ultrasonic import Ultrasonic

from time import sleep

class Incremental_PID:
    ''' PID controller'''
    def __init__(self,P=0.0,I=0.0,D=0.0):
        self.setPoint = 0.0
        self.Kp = P
        self.Ki = I
        self.Kd = D
        self.last_error = 0.0
        self.P_error = 0.0
        self.I_error = 0.0
        self.D_error = 0.0
        self.I_saturation = 10.0
        self.output = 0.0

    # PID Calculation
    def PID_compute(self,feedback_val):
        error = self.setPoint - feedback_val
        self.P_error = self.Kp * error
        self.I_error += error 
        self.D_error = self.Kd * (error - self.last_error)
        if (self.I_error < -self.I_saturation ):
            self.I_error = -self.I_saturation
        elif (self.I_error > self.I_saturation):
            self.I_error = self.I_saturation
        
        self.output = self.P_error + (self.Ki * self.I_error) + self.D_error
        self.last_error = error
        return -self.output

    def setKp(self,proportional_gain):
        
        self.Kp = proportional_gain

    def setKi(self,integral_gain):
        
        self.Ki = integral_gain

    def setKd(self,derivative_gain):

        self.Kd = derivative_gain

    def setI_saturation(self,saturation_val):

        self.I_saturation = saturation_val

class Rover:
    def __init__(self):
        self.clamp_mode = 0  # 0 = open, 1 = closed
        self.servo = Servo()  # Initialize the servo
        self.motor = tankMotor()  # Initialize the motor
        self.sonic = Ultrasonic()  # Initialize the ultrasonic sensor
        self.pid = Incremental_PID(1, 0, 0.0025)  # PID for distance and position control
        self.color_red = [0, 118, 31, 6, 255, 255]  # HSV range for red ball
        self.camera = Camera(preview_size=(320, 240), stream_size=(320, 240))

    def close(self):
        self.servo.setServoStop()
        self.motor.close()
        self.sonic.close()

    def block_detect(self, video):
        try:
            # Preprocessing
            gs_frame = cv2.GaussianBlur(video, (5, 5), 0)
            gs_frame = cv2.cvtColor(gs_frame, cv2.COLOR_BGR2HSV)
            gs_frame = cv2.erode(gs_frame, np.ones((5, 5), np.uint8), iterations=1)
            gs_frame = cv2.dilate(gs_frame, np.ones((2, 2), np.uint8), iterations=1)

            # Default to red ball detection
            inRange_hsv = cv2.inRange(gs_frame, tuple(self.color_red[:3]), tuple(self.color_red[3:]))
            
            # cv2.imshow("Image", inRange_hsv)
            cv2.waitKey(1)  # Allow window to update (fixed typo: waitkey → waitKey)

            # Contour detection
            cnts = cv2.findContours(inRange_hsv.copy(), cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)[-2]
            if not cnts:
                self.motor.setMotorModel(0, 0)  # Stop if no ball detected
                return

            c = max(cnts, key=cv2.contourArea)
            ((x, y), radius) = cv2.minEnclosingCircle(c)
            M = cv2.moments(c)
            center = None
            if M["m00"] > 0:
                center = (int(M["m10"] / M["m00"]), int(M["m01"] / M["m00"]))
                if radius < 10:
                    center = None

            if center:
                D = round(1660 / (2 * radius))  # Distance in cm (adjust for ball size)
                x = self.pid.PID_compute(center[0])  # Target center x = 200 (middle of 0-400)
                d = self.pid.PID_compute(D)  # Target distance = 14 cm (middle of 8-20 cm range for ball)

                if radius > 15:  # Significant object size (adjust for ball)
                    # Linear scaling: reduce speed as distance decreases
                    cv2.circle(video, center, 3, (255, 0, 0), 5)
                    cv2.circle(video, center, int(radius), (0, 255, 0), 2)

                    print("This is the distance: ", D)
                    print("This is the x value: ", x)
                    if d < 9:  # Too close (negative PID indicates error below target)
                        pass
                        # self.motor.setMotorModel(-900, -900)  # Move backward
                    elif d > 12:  # Too far (positive PID indicates error above target)
                        pass
                        # self.motor.setMotorModel(900, 900)  # Move forward
                    else:  # In range (approximately 8-20 cm)
                        if x < 85:  # Ball to the left
                            pass
                        # self.motor.setMotorModel(-900, 900)  # Turn left (corrected from original)
                        elif x > 315:
                            pass
                            # Ball to the right
                            # self.motor.setMotorModel(900, -900)  # Turn right (corrected from original)
                        else:  # Centered and in range: Pick up red ball
                            # self.motor.setMotorModel(0, 0)  # Stop
                            self.lower_gripper()  # Lower gripper
                            sleep(1)
                            self.pick_up()  # Pick up ball
                            sleep(1)
                            self.raise_gripper()
                            sleep(0.5)
                            # self.motor.setMotorModel(1200, 1200)  # Move forward with ball
                            sleep(2)  # Move for 2 seconds
                            # self.motor.setMotorModel(0, 0)  # Stop
                            sleep(0.5)
                            self.lower_gripper()  # Lower gripper
                            sleep(0.5)
                            self.drop()  # Drop ball
                            sleep(0.5)
                            self.raise_gripper()  # Raise gripper
                            cv2.destroyAllWindows()  # Close display after one cycle
                else:
                    self.motor.setMotorModel(0, 0)  # Stop if object too small
            else:
                self.motor.setMotorModel(0, 0)  # Stop if no valid center
        except Exception as e:
            print(f"Error in block_detect: {e}")
            self.motor.setMotorModel(0, 0)  # Stop on error
    
    def lower_gripper(self):
        """Lower the gripper (vertical position, channel 0) to 90 degrees."""
        self.servo.setServoAngle('0', 90)  # Lower to 90° (adjust as needed)

    def pick_up(self):
        """Close the gripper (channel 1) to pick up the ball."""
        self.clamp_mode = 1  # Set to closed state
        self.servo.setServoAngle('1', 0)  # Close gripper to 0° (adjust for closing angle)

    def drop(self):
        """Open the gripper (channel 1) to drop the ball."""
        self.clamp_mode = 0  # Set to open state
        self.servo.setServoAngle('1', 180)  # Open gripper to 180° (adjust for opening angle)

    def raise_gripper(self):
        """Raise the gripper (vertical position, channel 0) to 140 degrees (default)."""
        self.servo.setServoAngle('0', 0)

    def move(self):
        # Get distance from ultrasonic sensor
        distance = self.sonic.get_distance()
        print("Ultrasonic distance is " + str(distance) + "CM")

        # Check if distance is valid
        if distance != 0:
            # If distance is less than 45 cm, move backward and turn left
            if distance < 45:
                self.motor.setMotorModel(-1500, -1500)
                sleep(0.4)
                self.motor.setMotorModel(-1500, 1500)
                sleep(0.2)
            # Otherwise, move forward
            else:
                self.motor.setMotorModel(1500, 1500)
        sleep(0.2)

if __name__ == '__main__':
    rover = Rover()
    
    try:
        # Use the Camera class from camera.py
        camera = rover.camera  # Access the Camera instance initialized in __init__
        camera.start_stream()  # Start the video stream (using JpegEncoder for streaming)

        while True:
            # Capture frame using the Camera class
            frame = camera.get_frame()
            nparr = np.frombuffer(frame, np.uint8)
            frame_np = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

            if frame is None:
                print("Failed to capture frame. Retrying...")
                continue
            
            # Ensure frame is in BGR format (picamera2 outputs BGR888 by default)
            rover.block_detect(frame_np)

    except KeyboardInterrupt:
        print("Program interrupted")
    finally:
        rover.close()
        cv2.destroyAllWindows()