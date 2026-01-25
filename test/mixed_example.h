#ifndef MIXED_EXAMPLE_H
#define MIXED_EXAMPLE_H

// 複合的な例 - 複数のパターンを含む

// 基本的なデータ型
struct DataPoint {
  int timestamp;
  float value;
  bool isValid;
};

// Observerパターンの例
class Observer {
public:
  virtual ~Observer();
  virtual void update(DataPoint data);
};

class Subject {
public:
  Subject();
  ~Subject();
  void attach(Observer* observer);
  void detach(Observer* observer);
  void notify(DataPoint data);

protected:
  Observer* observers[10];
  int observerCount;
};

// 具体的な実装
class DataCollector : public Subject {
public:
  DataCollector();
  ~DataCollector();
  void collectData(DataPoint data);

private:
  DataPoint lastData;
  int collectionCount;
};

class DataDisplay : public Observer {
public:
  DataDisplay();
  ~DataDisplay();
  void update(DataPoint data);
  void display();

private:
  DataPoint currentData;
};

class FileWriter : public Observer {
public:
  FileWriter();
  ~FileWriter();
  void update(DataPoint data);
  void flush();

private:
  FILE* file;
  int bufferSize;
};

// Factory パターンの例
class ObjectFactory {
public:
  ObjectFactory();
  virtual ~ObjectFactory();
  
  virtual Observer* createObserver();

protected:
  int createdCount;
};

#endif // MIXED_EXAMPLE_H
