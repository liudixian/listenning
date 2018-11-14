
class PozyxDevice{
  private int ID;
  private int[] pos_x = new int [positionHistoryLength];
  private int[] pos_y = new int [positionHistoryLength];
  private int[] pos_z = new int [positionHistoryLength];
  
  public PozyxDevice(int ID){this.ID = ID;}
  
  public void addPosition(int x, int y, int z){
    System.arraycopy(pos_x, 0, pos_x, 1, positionHistoryLength - 1);
    System.arraycopy(pos_y, 0, pos_y, 1, positionHistoryLength - 1);
    System.arraycopy(pos_z, 0, pos_z, 1, positionHistoryLength - 1);
    
    pos_x[0] = x;
    pos_y[0] = y;
    pos_z[0] = z;
  }
  
  public int[] getCurrentPosition(){
    int[] position ={pos_x[0], pos_y[0], pos_z[0]};
    return position;
  }
}
