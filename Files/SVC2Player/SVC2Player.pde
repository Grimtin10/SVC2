/*----!!!!!IMPORTANT!!!!!----*/
/*-----Comment out file!-----*/

import com.hamoid.*;

byte[] file;

String filename = "result3";

int w;
int h;
int frame=0;

int blockSize;

int currentIndex = 0;

Block[][] blocks;

VideoExport out;

void setup() {
  size(1, 1);
  file = loadBytes(filename+".sv2");
  
  //File header parsing
  byte[] _w = new byte[2];
  byte[] _h = new byte[2];
  byte[] _blockSize = new byte[4];
  _w[0] = file[0];
  _w[1] = file[1];
  _h[0] = file[2];
  _h[1] = file[3];
  _blockSize[0] = file[4];
  _blockSize[1] = file[5];
  _blockSize[2] = file[6];
  _blockSize[3] = file[7];
  
  currentIndex = 8;
  
  w = bytesToShort(_w);
  h = bytesToShort(_h);
  blockSize = bytesToInt(_blockSize);
  
  println(w, h, blockSize);
  
  surface.setSize(w, h);
  
  blocks = new Block[w/blockSize][h/blockSize];
  
  for(int x=0;x<blocks.length;x++){
    for(int y=0;y<blocks[0].length;y++){
      blocks[x][y]=new Block(x*blockSize,y*blockSize,blockSize);
    }
  }
  
  out = new VideoExport(this,"result.mp4");
  out.startMovie();
  
  frameRate(30);
  
  noSmooth();
}

void draw() {
  surface.setTitle("FPS: "+frameRate);
  
  if(currentIndex >= file.length-1) {
    out.endMovie();
    exit();
  }
  
  /*-----CHUNK TYPE 0-----*/
  if(currentIndex < file.length && file[currentIndex] == 0x00) {
    
    byte[] _len = new byte[4];
    
    currentIndex++;
    
    for(int i = 0; i < _len.length; i++) {
      _len[i] = file[currentIndex];
      currentIndex++;
    }
    
    int len = bytesToInt(_len);
    
    int dataSize = 8;
    
    for(int i = 0; i < len/dataSize; i++) {
      byte[] _x1 = new byte[2];
      byte[] _y1 = new byte[2];
      byte[] _x2 = new byte[2];
      byte[] _y2 = new byte[2];
      
      _x1[0] = file[currentIndex];
      currentIndex++;
      _x1[1] = file[currentIndex];
      currentIndex++;
      _y1[0] = file[currentIndex];
      currentIndex++;
      _y1[1] = file[currentIndex];
      currentIndex++;
      _x2[0] = file[currentIndex];
      currentIndex++;
      _x2[1] = file[currentIndex];
      currentIndex++;
      _y2[0] = file[currentIndex];
      currentIndex++;
      _y2[1] = file[currentIndex];
      currentIndex++;
      
      short x1 = bytesToShort(_x1);
      short y1 = bytesToShort(_y1);
      short x2 = bytesToShort(_x2);
      short y2 = bytesToShort(_y2);
      
      blocks[x1][y1].getBlockPos(x2-w,y2);
    }
  }
  
  /*-----CHUNK TYPE 1-----*/
  if(currentIndex < file.length && file[currentIndex] == 0x01) {
    
    byte[] _len = new byte[4];
    
    currentIndex++;
    
    for(int i = 0; i < _len.length; i++) {
      _len[i] = file[currentIndex];
      currentIndex++;
    }
    
    int len = bytesToInt(_len);
    
    int dataSize = 4 + blockSize * blockSize * 3;
    
    for(int i = 0; i < len / dataSize; i ++) {
      byte[] _x = new byte[2];
      byte[] _y = new byte[2];
      
      _x[0] = file[currentIndex];
      currentIndex++;
      _x[1] = file[currentIndex];
      currentIndex++;
      _y[0] = file[currentIndex];
      currentIndex++;
      _y[1] = file[currentIndex];
      currentIndex++;
      
      short x = bytesToShort(_x);
      short y = bytesToShort(_y);
      
      byte[] colors = new byte[blockSize * blockSize * 3];
      PImage img = new PImage(blockSize, blockSize);
      
      for(int j = 0; j < colors.length; j++){
        colors[j] = file[currentIndex];
        currentIndex++;
      }
      
      for(int j = 0; j < colors.length; j+=3){
        img.pixels[j/3] = color(colors[j]&0xFF, colors[j + 1]&0xFF, colors[j + 2]&0xFF);
      }
      
      Block b = new Block(x*blockSize,y*blockSize,img,blockSize);
      blocks[x][y] = b;
    }
  }
  if(currentIndex < file.length && file[currentIndex]!=0x00&&file[currentIndex]!=0x01){
    System.err.println("ERR: Invalid chunk type " + (int)file[currentIndex] + " (hex "+hex(file[currentIndex], 2)+") at " + currentIndex);
    noLoop();
  }
  
  for(int x=0;x<blocks.length;x++){
    for(int y=0;y<blocks[0].length;y++){
      blocks[x][y].render();
    }
  }
  frame++;
  out.saveFrame();
}

public static byte[] longToBytes(long l) {
  byte[] result = new byte[8];
  for (int i = 7; i >= 0; i--) {
    result[i] = (byte)(l & 0xFF);
    l >>= 8;
  }
  return result;
}

public static long bytesToLong(final byte[] b) {
  long result = 0;
  for (int i = 0; i < 8; i++) {
     result <<= 8;
     result|=(b[i] & 0xFF);
  }
  return result;
}

public static byte[] shortToBytes(short l) {
  byte[] result=new byte[2];
  for (int i = 1; i >= 0; i--) {
    result[i]=(byte)(l & 0xFF);
    l>>=8;
  }
  return result;
}

public static short bytesToShort(final byte[] b) {
  short result = 0;
  for (int i = 0; i < 2; i++) {
     result <<= 8;
     result|=(b[i] & 0xFF);
  }
  return result;
}

public static byte[] intToBytes(int l) {
  byte[] result=new byte[4];
  for (int i = 3; i >= 0; i--) {
    result[i]=(byte)(l & 0xFF);
    l>>=8;
  }
  return result;
}

public static int bytesToInt(final byte[] b) {
  int result = 0;
  for (int i = 0; i < 4; i++) {
     result <<= 8;
     result|=(b[i] & 0xFF);
  }
  return result;
}
