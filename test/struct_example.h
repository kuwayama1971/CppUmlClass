#ifndef STRUCT_EXAMPLE_H
#define STRUCT_EXAMPLE_H

// 構造体の定義
struct Point {
  int x;
  int y;
  void display();
};

struct Color {
  unsigned char red;
  unsigned char green;
  unsigned char blue;
  unsigned char alpha;
};

// 構造体と継承の例
struct Shape {
  Color color;
  virtual ~Shape();
  virtual void draw();

protected:
  int lineWidth;
};

struct Rectangle : public Shape {
  int width;
  int height;
  void draw();
};

struct Circle : public Shape {
  int radius;
  void draw();
};

#endif // STRUCT_EXAMPLE_H
