#ifndef VIRTUAL_METHODS_H
#define VIRTUAL_METHODS_H

// 仮想メソッドの例
class Shape {
public:
  Shape();
  virtual ~Shape();
  
  virtual void draw() = 0;
  virtual double getArea() = 0;
  virtual double getPerimeter() = 0;
  
  void setColor(int r, int g, int b);

protected:
  int colorR;
  int colorG;
  int colorB;
  bool visible;
};

class Polygon : public Shape {
public:
  Polygon();
  ~Polygon();
  
  void draw();
  double getArea();
  double getPerimeter();
  
  void setVertices(int count);

protected:
  int vertexCount;
  float* vertices;
};

class Triangle : public Polygon {
public:
  Triangle();
  ~Triangle();
  
  void draw();
  double getArea();
  double getPerimeter();

private:
  float side1;
  float side2;
  float side3;
};

class Rectangle : public Polygon {
public:
  Rectangle();
  ~Rectangle();
  
  void draw();
  double getArea();
  double getPerimeter();

private:
  float width;
  float height;
};

class Circle : public Shape {
public:
  Circle();
  ~Circle();
  
  void draw();
  double getArea();
  double getPerimeter();
  
  void setRadius(float r);

private:
  float radius;
};

#endif // VIRTUAL_METHODS_H
