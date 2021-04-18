/*----!!!!!IMPORTANT!!!!!----*/
/*-------Format file!!-------*/

import com.hamoid.*;
import java.nio.file.*;
import java.io.*;
import static java.nio.file.StandardOpenOption.*;

//Video frames
PImage cur; //Original
Block[][] res; //Result

//Video resolution
int w=384;
int h=216;

//Video info
int frames=2731; //Total frames
int frame=-1; //Current frame
int refreshRate=120; //I-Frame refresh rate

//Block info
int blockSize=8; //Size of block in pixels
int searchRange=10; //Search range of block
float updateThresh=2500; //Threshold to update block

//MP4 Export
VideoExport out;

ArrayList<BlockPos> motions = new ArrayList<BlockPos>();
ArrayList<BlockUpdate> updates = new ArrayList<BlockUpdate>();

String filename="result1";

void setup(){
  //Set size of window
  size(0,0);
  surface.setSize(w*3,h);
  
  //Load images
  cur=loadImage("frame0001.png"); //Load original frame
  //Create result frame
  res=new Block[w/blockSize][h/blockSize];
  for(int x=0;x<res.length;x++){
    for(int y=0;y<res[0].length;y++){
      res[x][y]=new Block(x*blockSize,y*blockSize,blockSize);
    }
  }
  for(int x=0;x<res.length;x++){
    for(int y=0;y<res[0].length;y++){
      res[x][y].getBlock(cur);
      updates.add(new BlockUpdate(res[x][y],new BlockPos((short)x,(short)y)));
    }
  }
  
  out=new VideoExport(this,"video.mp4");
  out.startMovie();
  
  String[] blank=new String[0];
  saveStrings(filename+".sv2",blank);
  
  byte[] header=new byte[8];
  byte[] _w=shortToBytes((short)w);
  byte[] _h=shortToBytes((short)h);
  byte[] _blockSize=intToBytes(blockSize);
  header[0]=_w[0];
  header[1]=_w[1];
  header[2]=_h[0];
  header[3]=_h[1];
  header[4]=_blockSize[0];
  header[5]=_blockSize[1];
  header[6]=_blockSize[2];
  header[7]=_blockSize[3];
  
  fwrite(sketchPath()+"/"+filename+".sv2",header,true);
}

void draw(){
  //Increment frame
  frame++;
  
  motions.clear();
  updates.clear();
  
  if(frame==frames-1){
    out.endMovie();
    println("Finished!");
    exit();
  }
  
  cur=loadImage("frame"+addZeros(frame+1)+".png"); //Load current frame...
  
  //Draw original
  image(cur,0,0,w,h);
  image(cur,w*2,0,w,h);
  
  if(frame%refreshRate==0||frame==0){ //...and if it is time for an I-frame make it...
    for(int x=0;x<res.length;x++){
      for(int y=0;y<res[0].length;y++){
        res[x][y].getBlock(cur);
        updates.add(new BlockUpdate(res[x][y],new BlockPos((short)x,(short)y)));
      }
    }
  } else { //...otherwise process the frame
    processFrame();
  }
  
  surface.setTitle("FPS: "+frameRate);
  
  //Draw result
  for(int x=0;x<res.length;x++){
    for(int y=0;y<res[0].length;y++){
      res[x][y].render();
    }
  }
  
  out.saveFrame();
  writeFrame();
}

//Write a frame to the file
void writeFrame(){
  //Chunk sizes for header
  int motionHeaderSize=motions.size()*4;
  int updateHeaderSize=updates.size()*4+updates.size()*blockSize*blockSize*3;
  //println(4*blockSize*blockSize*3, updateHeaderSize, updates.size()*4+updates.size()*blockSize*blockSize*3);
  
  //Resulting bytes
  ArrayList<Byte> frame=new ArrayList<Byte>();
  
  /*-----CHUNK TYPE 0-----*/
  
  //Create header
  frame.add((byte)0x00);
  
  byte[] header1=intToBytes(motionHeaderSize); //Header - Size in bytes
  for(int i=0;i<header1.length;i++){
    frame.add(header1[i]);
  }
  
  //Add data
  for(int i=0;i<motions.size();i++){
    byte[] x=shortToBytes(motions.get(i).x);
    byte[] y=shortToBytes(motions.get(i).y);
    for(int j=0;j<x.length;j++){
      frame.add(x[j]);
    }
    for(int j=0;j<y.length;j++){
      frame.add(y[j]);
    }
  }
  
  /*-----CHUNK TYPE 1-----*/
  
  //Create header
  frame.add((byte)0x01);
  
  byte[] header2=intToBytes(updateHeaderSize); //Header - Size in bytes
  for(int i=0;i<header2.length;i++){
    frame.add(header2[i]);
  }
  
  //Add data
  //TODO: finish commenting this rename things and format it
  for(int i=0;i<updates.size();i++){
    byte[] x=shortToBytes(updates.get(i).pos.x);
    byte[] y=shortToBytes(updates.get(i).pos.y);
    for(int j=0;j<x.length;j++){
      frame.add(x[j]);
    }
    for(int j=0;j<y.length;j++){
      frame.add(y[j]);
    }
    Block t=updates.get(i).b;
    for(int j=0;j<t.col.pixels.length;j++){
      color t2=t.col.pixels[j];
      byte r=(byte)red(t2);
      byte g=(byte)green(t2);
      byte b=(byte)blue(t2);
      frame.add(r);
      frame.add(g);
      frame.add(b);
    }
  }
  
  byte[] t=new byte[frame.size()];
  for(int i=0;i<t.length;i++){
    t[i]=frame.get(i);
  }
  
  fwrite(sketchPath()+"/"+filename+".sv2",t,true);
}

void fwrite(String filename, byte[] data, boolean append){
  Path file = Paths.get(filename);
  OutputStream output = null;
  try{
    if(append&&Files.exists(file)){
      output = new BufferedOutputStream(Files.newOutputStream(file, APPEND));
    }else{
      output = new BufferedOutputStream(Files.newOutputStream(file, CREATE));
    }
    output.write(data);
    output.flush();
    output.close();
  }catch(Exception e){
    System.err.println("Error: " + e);
  }
}

//Process the frame for compression
void processFrame(){
  for(int x=0;x<res.length;x++){
    for(int y=0;y<res[0].length;y++){
      noFill();
      strokeWeight(1);
      
      //Best block
      float best=2147483647;
      int bestX=0;
      int bestY=0;
      
      Block t=new Block(x*blockSize,y*blockSize,blockSize); //Original block
      t.getBlock(0,0);
      
      for(int _x=-searchRange;_x<searchRange;_x++){
        for(int _y=-searchRange;_y<searchRange;_y++){
          Block t2=new Block(x*blockSize+_x,y*blockSize+_y,blockSize); //Block to be compared
          t2.getBlock(w,0); //Get the pixels for that block
          
          //Current pos
          int curX=x*blockSize+_x;
          int curY=y*blockSize+_y;
          
          float d=t2.compare(t)+dist(curX,curY,x*blockSize,y*blockSize); //Distance (in color) between blocks
          
          if(d<best&&curX>0&&curX<w){ //If this block is a better fit, use it
            best=d;
            bestX=curX+w;
            bestY=curY;
          }
        }
      }
      
      //Draw compression info
      
      if(best<updateThresh){ //Update block if too different from original
        res[x][y].getBlockPos(bestX,bestY);
        stroke(255,0,0);
        rect(x*blockSize+w+w,y*blockSize,blockSize,blockSize);
        stroke(0);
        line(x*blockSize+w+w,y*blockSize,bestX+w,bestY);
        fill(0);
        ellipse(bestX+w,bestY,2,2);
        if(x*blockSize!=bestX||y*blockSize!=bestY){
          motions.add(new BlockPos((short)(x),(short)(y)));
          motions.add(new BlockPos((short)bestX,(short)bestY));
        }
      } else {
        res[x][y].getBlockPos(x*blockSize,y*blockSize);
        updates.add(new BlockUpdate(res[x][y],new BlockPos((short)x,(short)y)));
        stroke(0,255,0);
        fill(0,255,0,64);
        rect(x*blockSize+w+w,y*blockSize,blockSize,blockSize);
      }
    }
  }
  
  if(frame%10==0){
    println("frame "+frame+" done");
  }
}

String addZeros(int num){
  if(num<10){
    return "000"+num;
  } else if(num<100){
    return "00"+num;
  } else if(num<1000){
    return "0"+num;
  }
  return ""+num;
}

public static byte[] longToBytes(long l){
  byte[] result=new byte[8];
  for (int i=7;i>=0;i--) {
    result[i]=(byte)(l&0xFF);
    l>>=8;
  }
  return result;
}

public static long bytesToLong(final byte[] b){
  long result=0;
  for (int i=0;i<8;i++) {
     result<<=8;
     result|=(b[i]&0xFF);
  }
  return result;
}

public static byte[] shortToBytes(short l){
  byte[] result=new byte[2];
  for (int i=1;i>=0;i--) {
    result[i]=(byte)(l&0xFF);
    l>>=8;
  }
  return result;
}

public static short bytesToShort(final byte[] b){
  short result=0;
  for (int i=0;i<2;i++) {
     result<<=8;
     result|=(b[i]&0xFF);
  }
  return result;
}

public static byte[] intToBytes(int l){
  byte[] result=new byte[4];
  for (int i=3;i>=0;i--) {
    result[i]=(byte)(l&0xFF);
    l>>=8;
  }
  return result;
}

public static int bytesToInt(final byte[] b){
  int result=0;
  for (int i=0;i<4;i++) {
     result<<=8;
     result|=(b[i]&0xFF);
  }
  return result;
}
