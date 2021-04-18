public class Block{
  int x,y,s;
  PImage col;
  
  public Block(int x,int y,int s){
    this.x=x;
    this.y=y;
    this.s=s;
    col=new PImage(s,s,RGB);
  }
  
  public void getBlock(PImage src){
    col=src.get(x,y,s,s);
  }
  
  public void getBlock(int xOff,int yOff){
    col=get(x+xOff,y+yOff,s,s);
  }
  
  public void getBlockPos(int x,int y){
    col=get(x,y,s,s);
  }
  
  public void render(){
    image(col,x+w,y);
  }
  
  public float compare(Block b){
    float dist=0;
    for(int i=0;i<col.pixels.length;i++){
      color c1=col.pixels[i];
      color c2=b.col.pixels[i];
      dist+=dist(red(c1),green(c1),blue(c1),red(c2),green(c2),blue(c2));
    }
    return dist;
  }
}
