#ifndef ACCESS_MODIFIER_H
#define ACCESS_MODIFIER_H

// アクセス修飾子の例
class DataHandler {
public:
  DataHandler();
  ~DataHandler();
  
  // Public メンバー
  void publicMethod();
  int publicValue;

protected:
  // Protected メンバー
  void protectedMethod();
  void updateInternalState();
  char buffer[512];
  int state;

private:
  // Private メンバー
  void privateMethod();
  bool validateData();
  int internalCounter;
  void* internalData;
};

class Logger {
public:
  void log(const char* message);
  void error(const char* message);

private:
  FILE* logFile;
  int logLevel;
  bool initialized;
};

#endif // ACCESS_MODIFIER_H
