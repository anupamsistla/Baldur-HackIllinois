import fcntl  # Import the fcntl module
import struct 
import socket
import threading

import time
import socket
import threading

class RoverServer:
    def __init__(self, rover, port=5005):
        self.rover = rover

        self.host = self.get_interface_ip()
        self.port = port
        self.server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.client_threads = []
        self.running = True

    def get_interface_ip(self):
        # Get the IP address of the wlan0 interface
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)  # Create a UDP socket
        return socket.inet_ntoa(fcntl.ioctl(s.fileno(), 0x8915, struct.pack('256s', b'wlan0'[:15]))[20:24])  # Get the IP address of the wlan0 interface

    def start(self):
        self.server_socket.bind((self.host, self.port))
        self.server_socket.listen(5)
        print(f"Server listening on {self.host}:{self.port}")
        
        while self.running:
            try:
                conn, addr = self.server_socket.accept()
                client_thread = threading.Thread(target=self.handle_client, args=(conn, addr))
                client_thread.daemon = True
                client_thread.start()
                self.client_threads.append(client_thread)
            except OSError:
                break  # Stop accepting new connections if server is closed

    def handle_client(self, conn, addr):
        print(f"Connection from {addr}")
        try:
            while self.running:
                data = conn.recv(1024).decode()
                if not data:
                    break
                print(f"Received command: {data}")

                if data.strip() == "run":
                    self.rover.run()
                elif data.strip() == "pause":
                    self.rover.pause()

                print(self.rover.running)

                response = f"Command '{data}' executed"
                conn.send(response.encode())
        except Exception as e:
            print(f"Error handling client {addr}: {e}")
        finally:
            conn.close()
            print(f"Connection closed for {addr}")

    def stop(self):
        print("Stopping server...")
        
        self.running = False
        self.server_socket.close()
        for thread in self.client_threads:
            thread.join()

        print("Server stopped.")
        