#ifndef TYPES_HPP
#define TYPES_HPP

struct TGameInfo {
  uint32_t frameWidth, frameHeight;
  uint32_t playerXDelta, playerYDelta;
  int32_t enemyXDelta;
  uint32_t lives;
};

struct TSprite {
  uint32_t width, height;
  uint32_t xPos, yPos;
  uint32_t mask;
  uint32_t * data;
};

#endif // TYPES_HPP
