// Quick Visualization by Clement Zheng (c) 2019 | clementzheng.info
// 
// Create, display visual elements that update to USB serial input (e.g. from an Arduino).
// Add objects to visualization by adding new rows to the CSV files in the sketch's 'data' folder.
// Clickers:  display on/off events.
// Sliders:   display continuous values.
// Graphers:  display a line graph of incoming values.  

import processing.serial.*;

void setup() {
  setupSerial();
  size(1200, 800, P3D); //change width and height of windowed sketch here, comment out if you want fullscreen
  // fullScreen(P3D); //uncomment this if you want fullscreen, comment previous line
  loadObjects();
  textSize(15); // Change text size
}

void draw() {
  fill(255); // Change background color here
  noStroke();
  rect(0, 0, width, height);
  readSerial();
  updateObjects();
  displayObjects();
}




/////////////////
//             //
//   SERIAL    //
//             //
/////////////////

Serial[] SERIAL_PORT;
float[][] val;

void setupSerial() {
  for (int i=0; i<Serial.list().length; i++) {
    println("["+i+"] "+Serial.list()[i], 50, 90+i*15);
  }

  Table serial_table = loadTable("serial.csv", "header");
  SERIAL_PORT = new Serial[serial_table.getRowCount()];
  int port_counter = 0;
  for (TableRow row : serial_table.rows()) {
    int spi = row.getInt("SERIAL_PORT_INDEX");
    int br = row.getInt("BAUD_RATE");
    SERIAL_PORT[port_counter] = new Serial(this, Serial.list()[spi], br);
    port_counter++;
  }
}

int serial_unplugged_counter = 0;
void readSerial() {
  val = new float[SERIAL_PORT.length][0];
  for (int i=0; i<SERIAL_PORT.length; i++) {
    if (SERIAL_PORT[i].available() > 0) {
      String str =  SERIAL_PORT[i].readStringUntil('\n');
      if (str != null) {
        str = trim(str);
        //println(str);
        String[] readings = str.split(" ");
        val[i] = new float[readings.length];
        for (int j=0; j<readings.length; j++) {
          val[i][j] = parseFloat(readings[j]);
        }
      }
    }
  }
}


/////////////////
//             //
//   OBJECTS   //
//             //
/////////////////

ArrayList<Clicker> clickers = new ArrayList<Clicker>();
ArrayList<Slider> sliders = new ArrayList<Slider>();
ArrayList<Grapher> graphers = new ArrayList<Grapher>();

// Load Clicker, Slider, Grapher objects
void loadObjects() {

  Table table_clicker;
  Table table_slider;
  Table table_grapher;

  table_clicker = loadTable("clickers.csv", "header");
  for (TableRow row : table_clicker.rows()) {
    String n = row.getString("NAME");
    int spi = row.getInt("SERIAL_PORT_INDEX");
    int si = row.getInt("SERIAL_INDEX");
    float tv = row.getFloat("TRIGGER_VAL");
    boolean in = row.getString("INVERTED").equals("TRUE") || row.getString("INVERTED").equals("true") ? true : false;
    boolean tog = row.getString("TOGGLE").equals("TRUE") || row.getString("TOGGLE").equals("true") ? true : false;
    float x = row.getFloat("POS_X");
    float y = row.getFloat("POS_Y");
    float ww = row.getFloat("WIDTH");
    float hh = row.getFloat("HEIGHT");
    color cp = unhex(row.getString("COLOR_PASSIVE"));
    color ca = unhex(row.getString("COLOR_ACTIVE"));
    String ip = row.getString("IMG_PASSIVE");
    String ia = row.getString("IMG_ACTIVE");
    boolean sn = row.getString("SHOW_NAME").equals("TRUE") || row.getString("SHOW_NAME").equals("true") ? true : false;
    boolean sv = row.getString("SHOW_VAL").equals("TRUE") || row.getString("SHOW_VAL").equals("true") ? true : false;
    clickers.add(new Clicker(n, spi, si, tv, in, tog, x, y, ww, hh, cp, ca, ip, ia, sn, sv));
  }

  table_slider = loadTable("sliders.csv", "header");
  for (TableRow row : table_slider.rows()) {
    String n = row.getString("NAME");
    int spi = row.getInt("SERIAL_PORT_INDEX");
    int si = row.getInt("SERIAL_INDEX");
    float mi = row.getFloat("MIN");
    float ma = row.getFloat("MAX");
    boolean in = row.getString("INVERTED").equals("TRUE") || row.getString("INVERTED").equals("true") ? true : false;
    String dir = row.getString("DIRECTION");
    float x = row.getFloat("POS_X");
    float y = row.getFloat("POS_Y");
    float ww = row.getFloat("WIDTH");
    float hh = row.getFloat("HEIGHT");
    color cp = unhex(row.getString("COLOR_PASSIVE"));
    color ca = unhex(row.getString("COLOR_ACTIVE"));
    boolean sn = row.getString("SHOW_NAME").equals("TRUE") || row.getString("SHOW_NAME").equals("true") ? true : false;
    boolean sv = row.getString("SHOW_VAL").equals("TRUE") || row.getString("SHOW_VAL").equals("true") ? true : false;
    sliders.add(new Slider(n, spi, si, mi, ma, in, dir, x, y, ww, hh, cp, ca, sn, sv));
  }

  table_grapher = loadTable("graphers.csv", "header");
  for (TableRow row : table_grapher.rows()) {
    String n = row.getString("NAME");
    int spi = row.getInt("SERIAL_PORT_INDEX");
    int si = row.getInt("SERIAL_INDEX");
    float mi = row.getFloat("MIN");
    float ma = row.getFloat("MAX");
    int hs = row.getInt("HISTORY_SIZE");
    float x = row.getFloat("POS_X");
    float y = row.getFloat("POS_Y");
    float ww = row.getFloat("WIDTH");
    float hh = row.getFloat("HEIGHT");
    color cp = unhex(row.getString("COLOR_PASSIVE"));
    color ca = unhex(row.getString("COLOR_ACTIVE"));
    float lw = row.getFloat("LINE_WEIGHT");
    boolean sn = row.getString("SHOW_NAME").equals("TRUE") || row.getString("SHOW_NAME").equals("true") ? true : false;
    boolean sv = row.getString("SHOW_VAL").equals("TRUE") || row.getString("SHOW_VAL").equals("true") ? true : false;
    graphers.add(new Grapher(n, spi, si, mi, ma, hs, x, y, ww, hh, cp, ca, lw, sn, sv));
  }
}

void updateObjects() {
  for (Clicker c : clickers) {
    if (val[c.serial_port_index].length > c.serial_index) {
      c.update(val[c.serial_port_index][c.serial_index]);
    }
  }
  for (Slider s : sliders) {
    if (val[s.serial_port_index].length > s.serial_index) {
      s.update(val[s.serial_port_index][s.serial_index]);
    }
  }
  for (Grapher g : graphers) {
    if (val[g.serial_port_index].length > g.serial_index) {
      g.update(val[g.serial_port_index][g.serial_index]);
    }
  }
}

void displayObjects() {
  for (Clicker c : clickers) {
    c.display();
  }
  for (Slider s : sliders) {
    s.display();
  }
  for (Grapher g : graphers) {
    g.display();
  }
}

// Clicker Object
class Clicker {

  float val = 0;
  String name;
  int serial_port_index;
  int serial_index;
  float trigger_val;
  boolean inverted;
  boolean toggle;
  PVector pos;
  float w;
  float h;
  color color_passive;
  color color_active;
  PImage img_passive;
  PImage img_active;
  boolean show_name;
  boolean show_val;
  boolean active = false;
  boolean ctrig = false;
  boolean ptrig = false;

  Clicker(String n, int spi, int si, float tv, boolean in, boolean tog, float x, float y, float ww, float hh, color cp, color ca, String ip, String ia, boolean sn, boolean sv) {
    name = n;
    serial_port_index = spi;
    serial_index = si;
    trigger_val = tv;
    inverted = in;
    toggle = tog;
    pos = new PVector(x, y);
    w = ww;
    h = hh;
    color_passive = cp;
    color_active = ca;
    if (ip.length() > 0) {
      img_passive = loadImage(ip);
    }
    if (ia.length() > 0) {
      img_active = loadImage(ia);
    }
    show_name = sn;
    show_val = sv;
  }

  void update(float v) {
    val = v;
    ctrig = false;
    if (inverted && val < trigger_val) {
      ctrig = true;
    } else if (!inverted && val > trigger_val) {
      ctrig = true;
    }
    if (!toggle) {
      active = ctrig;
    } else {
      if (ctrig && !ptrig) {
        active = !active;
      }
    } 
    ptrig = ctrig;
  }

  void display() {
    noStroke();
    fill(color_passive);
    if (active) {
      fill(color_active);
    }
    rect(pos.x, pos.y, w, h);
    if (active && img_active != null) {
      image(img_active, pos.x, pos.y, w, h);
    } else if (!active && img_passive != null) {
      image(img_passive, pos.x, pos.y, w, h);
    }
    fill(0);
    textAlign(LEFT);
    if (show_name) {
      text(name, pos.x, pos.y - 4);
    }
    textAlign(RIGHT);
    if (show_val) {
      text(nf(val, 0, 1), pos.x + w, pos.y - 4);
    }
  }
}

// Slider Object
class Slider {

  float val = 0;
  String name;
  int serial_port_index;
  int serial_index;
  float min = 0;
  float max = 0;
  boolean inverted;
  String direction;
  PVector pos;
  float w;
  float h;
  color color_passive;
  color color_active;
  boolean show_name;
  boolean show_val;

  Slider(String n, int spi, int si, float mi, float ma, boolean in, String dir, float x, float y, float ww, float hh, color cp, color ca, boolean sn, boolean sv) {
    name = n;
    serial_port_index = spi;
    serial_index = si;
    min = mi;
    max = ma;
    inverted = in;
    direction = dir;
    pos = new PVector(x, y);
    w = ww;
    h = hh;
    color_passive = cp;
    color_active = ca;
    show_name = sn;
    show_val = sv;
  }

  void update(float v) {
    val = v;
  }

  void display() {
    noStroke();
    fill(color_passive);
    rect(pos.x, pos.y, w, h);
    fill(color_active);
    float ratio = map(val, min, max, 0, 1);
    ratio = constrain(ratio, 0, 1);
    if (direction.equals("VERTICAL") || direction.equals("vertical")) {
      if (inverted) {
        rect(pos.x, pos.y, w, h*ratio);
      } else {
        rect(pos.x, pos.y+h*(1-ratio), w, h*ratio);
      }
    } else {
      if (inverted) {
        rect(pos.x+w*(1-ratio), pos.y, w*ratio, h);
      } else {
        rect(pos.x, pos.y, w*ratio, h);
      }
    }
    fill(0);
    textAlign(LEFT);
    if (show_name) {
      text(name, pos.x, pos.y - 4);
    }
    if (show_val) {
      PVector vpos = new PVector(0, 0);
      PVector mipos = new PVector(0, 0);
      PVector mapos = new PVector(0, 0);
      if (direction.equals("VERTICAL") || direction.equals("vertical")) {
        if (inverted) {
          vpos.x = pos.x + w + 4;
          vpos.y = pos.y + h*ratio;
          mipos.x = pos.x + w + 4;
          mipos.y = pos.y;
          mapos.x = pos.x + w + 4;
          mapos.y = pos.y + h;
        } else {
          vpos.x = pos.x + w + 4;
          vpos.y = pos.y + h*(1-ratio);
          mipos.x = pos.x + w + 4;
          mipos.y = pos.y + h;
          mapos.x = pos.x + w + 4;
          mapos.y = pos.y;
        }
      } else {
        if (inverted) {
          vpos.x = pos.x + w*(1-ratio);
          vpos.y = pos.y + h + 7;
          mipos.x = pos.x + w;
          mipos.y = pos.y + h + 7;
          mapos.x = pos.x;
          mapos.y = pos.y + h + 7;
        } else {
          vpos.x = pos.x + w*ratio;
          vpos.y = pos.y + h + 7;
          mipos.x = pos.x;
          mipos.y = pos.y + h + 7;
          mapos.x = pos.x + w;
          mapos.y = pos.y + h + 7;
        }
      }
      if (direction.equals("VERTICAL") || direction.equals("vertical")) {
        textAlign(LEFT, CENTER);
      } else {
        textAlign(CENTER, CENTER);
      }
      text(nf(val, 0, 1), vpos.x, vpos.y);
      text(nf(min, 0, 1), mipos.x, mipos.y);
      text(nf(max, 0, 1), mapos.x, mapos.y);
    }
  }
}

// Grapher Object
class Grapher {

  float[] val;
  String name;
  int serial_port_index;
  int serial_index;
  float min = 0;
  float max = 0;
  int history_size;
  PVector pos;
  float w;
  float h;
  color color_passive;
  color color_active;
  float line_weight;
  boolean show_name;
  boolean show_val;

  Grapher(String n, int spi, int si, float mi, float ma, int hs, float x, float y, float ww, float hh, color cp, color ca, float lw, boolean sn, boolean sv) {
    name = n;
    serial_port_index = spi;
    serial_index = si;
    min = mi;
    max = ma;
    history_size = hs;
    val = new float[hs];
    for (int i=0; i<hs; i++) {
      val[i] = 0;
    }
    pos = new PVector(x, y);
    w = ww;
    h = hh;
    color_passive = cp;
    color_active = ca;
    line_weight = lw;
    show_name = sn;
    show_val = sv;
  }

  void update(float v) {
    for (int i=0; i<history_size-1; i++) {
      val[i] = val[i+1];
    }
    val[history_size-1] = v;
  }

  void display() {
    noStroke();
    fill(color_passive);
    rect(pos.x, pos.y, w, h);
    noFill();
    stroke(color_active);
    strokeWeight(line_weight);
    beginShape();
    for (int i=0; i<history_size; i++) {
      float xpos = map((float)i, 0, (float)history_size, pos.x, pos.x + w);
      float ypos = map(val[i], min, max, 0, h);
      ypos = constrain(ypos, 0, h);
      vertex(xpos, pos.y + h - ypos - line_weight/2);
    }
    endShape();
    noStroke();
    fill(0);
    textAlign(LEFT);
    if (show_name) {
      text(name, pos.x, pos.y - 4);
    }
    textAlign(LEFT, CENTER);
    if (show_val) {
      float ratio = map(val[history_size-1], min, max, 0, 1);
      ratio = constrain(ratio, 0, 1);
      text(nf(val[history_size-1], 0, 1), pos.x + w + 4, pos.y + h*(1-ratio));
      text(nf(min, 0, 1), pos.x + w + 4, pos.y + h);
      text(nf(max, 0, 1), pos.x + w + 4, pos.y);
    }
  }
}
