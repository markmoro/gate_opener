/*
  Non replay request
  
  This code is a simple 2 request secure request for Arduino
  It works by having a shatred seceret between the client and the arduino (hmacKey).
  The first request generated a random token which is passed back to the client.
  The client then appends a command ("open") to the token and creates the hmac digest which it sends back to the server.
  The server can then verify the request using the hmac key.

  The above method should be able to avoid replay attacks.  There are a few limitations:-
  
    -  There is only one token which changes on every token request.   This means that it only supports one client
       at a time.   There is also no checking arround this so if multiple client use the server it won't work properly
       
    -  The random() function is somewhat predicatble.  An improvement would be to seed the random geneator with
       some "noise" from an analogue pin.
 
   
 */

#include <SPI.h>
#include <Ethernet.h>
#include "sha1.h"

// Enter a MAC address and IP address for your controller below.
// The IP address will be dependent on your local network:
byte mac[] = { 
  0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };
IPAddress ip(192,168,1,177);
int openPin = 4;                 // LED connected to digital pin 13
int inPin  =2;
// Initialize the Ethernet server library
// with the IP address and port you want to use 
// (port 80 is default for HTTP):
EthernetServer server(80);
//Servo myservo;  // create servo object to control a servo 
char token[16]; 

const int requestBufferSize=512;
char requestBuffer[requestBufferSize];

//  Randon key for HMAC - Should change
char * hmacKey = "TESTHMACKEY";


void setup() {
  pinMode(openPin, OUTPUT); 
  pinMode(inPin, INPUT); 
  digitalWrite(openPin, LOW);
 // Open serial communications and wait for port to open:
  Serial.begin(9600);
  //  myservo.attach(9);  // attaches the servo on pin 9 to the servo object 
  
   while (!Serial) {
    ; // wait for serial port to connect. Needed for Leonardo only
  }

  // start the Ethernet connection and the server:
  Ethernet.begin(mac, ip);
  server.begin();
  Serial.print("server is at ");
  Serial.println(Ethernet.localIP());
}

void generateToken(EthernetClient client) {

 
  for(int i=0;i<15;i++) {
      token[i]= (char)random(26)+65;
  }
  token[15]=0;
  //  Just return the token (no markup)
  
     Serial.println("Token ");
     Serial.println(token);
     client.println("HTTP/1.1 200 OK");
     client.println("Content-Type: text/plain");
     client.println("Connection: close");
     client.println();          
      client.println(token);
           Serial.println("Sent ");

 // client.println("Content-Type: text/plain");
  //client.println("Connection: close");  // the connection will be closed after completion of the response  
}

void openGate() {
     Serial.println("bbOpen Suceess ");
 //   digitalWrite(openPin, HIGH);  
  //  delay(500);                  // waits for a second
  //  digitalWrite(openPin, LOW);
}


void hashToString(uint8_t* hash, char* buffer) {
  int i;
  for (i=0; i<20; i++) {
    buffer[i*2] = "0123456789abcdef"[hash[i]>>4];
    buffer[i*2+1] = "0123456789abcdef"[hash[i]&0xf];
  }
  buffer[40]=0;
}



void generateOpen(EthernetClient client, char * digest) {
  char hmBuffer[41];
  char checkString[100];
  Sha1.initHmac((uint8_t*)hmacKey,strlen(hmacKey));
  strcpy(checkString, token);
  strcat(checkString, "open");

  Sha1.print(checkString);
  Serial.println(checkString);
  client.println("HTTP/1.1 200 OK");
  client.println("Content-Type: text/plain");
  client.println("Connection: close");
  client.println();      
  
  hashToString(Sha1.resultHmac(),hmBuffer);
  Serial.println(digest);
  Serial.println("***");
  Serial.println(hmBuffer);
  Serial.println("***");

         
  if(strcmp(digest,hmBuffer) == 0) {
      client.println("OK");
      openGate();
  } else
      client.println("FAIL");

}




void checkButton() {
     // read the state of the pushbutton value:
  int buttonState = digitalRead(inPin);

  // check if the pushbutton is pressed.
  // if it is, the buttonState is HIGH:
  if (buttonState == HIGH) {     
    openGate();
  } 
}


void loop() {

  checkButton();
  // listen for incoming clients
  EthernetClient client = server.available();
  if (client) {
    Serial.println("new client");
    // an http request ends with a blank line
    boolean currentLineIsBlank = true;
    boolean isTokenRequest =false;
    boolean isOpenRequest =false;
    boolean digestSet =false;
    char digest[41];
    int bufPos =0;
    
    while (client.connected()) {
  
      if (client.available()) {
        char c = client.read();
        if(bufPos < (requestBufferSize-1)) {
          requestBuffer[bufPos]=c;
          bufPos++;
        }
        Serial.write(c);
        // if you've gotten to the end of the line (received a newline
        // character) and the line is blank, the http request has ended,
        // so you can send a reply
        if ((c == '\n' || c==0) && currentLineIsBlank) {
            if(isTokenRequest) {
              generateToken(client);
              break;
            }
            else if (isOpenRequest) {
               // Read next line
                bufPos =0;     
                 c = client.read();  
               while(client.available())
                {
      
                    requestBuffer[bufPos++]=c;
                    c=client.read(); 
                }
                requestBuffer[bufPos++]=c;
                requestBuffer[bufPos++]=0;
               if(strncmp(requestBuffer,"d=",2) == 0 && bufPos >41) {
                  strncpy(digest, requestBuffer+2, 40);
                  digest[40]=0;
                  Serial.println("Digest Rec");
                  Serial.println(requestBuffer);
                  digestSet = true;
                  generateOpen(client,digest);
               }
            
              break;
            }
      //      
        }
        if (c == '\n'){
          if(strncmp(requestBuffer,"GET /token",10) == 0) 
            isTokenRequest = true;
          if(strncmp(requestBuffer,"POST /open",10) == 0) 
            isOpenRequest = true;
    
  
           requestBuffer[bufPos]=0;     
           bufPos =0;                 
           currentLineIsBlank = true;
        } 
        else if (c != '\r') {
          // you've gotten a character on the current line
          currentLineIsBlank = false;
        }
      }
    }
    // give the web browser time to receive the data
    delay(1);
    // close the connection:
    client.stop();
    Serial.println("client disonnected");
  }
}

