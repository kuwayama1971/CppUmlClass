#ifndef COMPOSITION_H
#define COMPOSITION_H

// コンポジション関係の例
class Engine {
public:
  Engine();
  ~Engine();
  void start();
  void stop();

private:
  int horsePower;
  int rpm;
};

class Wheel {
public:
  Wheel();
  ~Wheel();
  void rotate();

private:
  int diameter;
  int pressure;
};

class Car {
public:
  Car();
  ~Car();
  void drive();
  void stop();

private:
  Engine engine;
  Wheel wheels[4];
  char licensePlate[20];
};

#endif // COMPOSITION_H
