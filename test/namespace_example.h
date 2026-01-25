#ifndef NAMESPACE_EXAMPLE_H
#define NAMESPACE_EXAMPLE_H

namespace Graphics {
  // グラフィックス関連クラス
  class Renderer {
  public:
    Renderer();
    ~Renderer();
    void render();
    void clear();

  private:
    int width;
    int height;
    void* context;
  };

  class Texture {
  public:
    Texture();
    ~Texture();
    void load(const char* filename);
    void bind();

  private:
    int textureId;
    int width;
    int height;
  };
}

namespace Math {
  // 数学関連クラス
  class Vector {
  public:
    Vector();
    Vector(float x, float y, float z);
    float magnitude();
    void normalize();

  private:
    float x;
    float y;
    float z;
  };

  class Matrix {
  public:
    Matrix();
    void identity();
    void multiply(const Matrix& other);

  private:
    float data[16];
  };
}

#endif // NAMESPACE_EXAMPLE_H
