// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import './Ship.sol';
import 'hardhat/console.sol';

struct Game {
  uint height;
  uint width;
  mapping(uint => mapping(uint => uint)) board;
  mapping(uint => int) xs;
  mapping(uint => int) ys;
}

contract Main {
  Game private game;
  uint private index;
  mapping(address => bool) private used;
  mapping(uint => address) private ships;
  mapping(uint => address) private owners;
  mapping(address => uint) private count;

  event Size(uint width, uint height);
  event Touched(uint ship, uint x, uint y);
  event Registered(
    uint indexed index,
    address indexed owner,
    uint x,
    uint y
  );

  constructor() {
    game.width = 50;
    game.height = 50;
    index = 1;
    emit Size(game.width, game.height);
  }

  /*
  Function to communicate with allies ships in order to 
  get their knowledgments (their maps)
  */
  function communication(uint i) private{
    Ship ship = Ship(ships[i]); // get the ship at the index i
    address owner = owners[i]; // get the owner of this ship

    // search allies of this ship --> same owner
    for (uint j = 1; j < index; j++) {

      // if we find an allie
      if (i != j && owners[j] == owner){
        console.log("Communication : %s <--> %s (allie)",i,j);
        Ship allie = Ship(ships[j]); // get the allie ship
        
        // get information of all his map
        for (uint x; x<game.height; x+=1){
          for (uint y; y<game.width; y+=1){
            uint value = allie.getValue(x,y); // get value for the position (x,y)
            if (value > 0){
              console.log("Allie informs : (%s,%s)=%s",x,y,value);
            }
            ship.communicate(x,y,value); // communicate --> update ship's map
          }
        }
      }
    }
  }

  function register() external {
    address ship = address(new Ship(msg.sender)); // get address of the new ship
    require(count[msg.sender] < 2, 'Only two ships');
    require(!used[ship], 'Ship alread on the board');
    require(index <= game.height * game.width, 'Too much ship on board');
    count[msg.sender] += 1;
    ships[index] = ship;
    owners[index] = msg.sender;
    (uint x, uint y) = placeShip(index);
    console.log("Register --> id:%s x:%s, y%s",index,x,y);
    Ship(ships[index]).update(x, y);
    emit Registered(index, msg.sender, x, y);
    used[ship] = true;
    index += 1;
  }

  function turn() external {
    bool[] memory touched = new bool[](index);
    for (uint i = 1; i < index; i++) {
      if (game.xs[i] < 0) continue;
      communication(i); // the ship at index i communicate
      Ship ship = Ship(ships[i]);
      //ship.printMap();
      ship.checkReset(i);
      (uint x, uint y) = ship.fire();
      console.log("FIRE --> id:%s x:%s, y%s",i,x,y);
      if (game.board[x][y] > 0) {
        console.log("TOUCHE");
        touched[game.board[x][y]] = true;
      }
    }
    for (uint i = 0; i < index; i++) {
      if (touched[i]) {
        emit Touched(i, uint(game.xs[i]), uint(game.ys[i]));
        game.xs[i] = -1;
      }
    }
  }

  function placeShip(uint idx) internal returns (uint, uint) {
    Ship ship = Ship(ships[idx]);
    (uint x, uint y) = ship.place(game.width, game.height);
    bool invalid = true;
    while (invalid) {
      if (game.board[x][y] == 0) {
        game.board[x][y] = idx;
        game.xs[idx] = int(x);
        game.ys[idx] = int(y);
        invalid = false;
      } else {
        uint newPlace = (x * game.width) + y + 1;
        x = newPlace % game.width;
        y = newPlace / game.width % game.height;
      }
    }
    return (x, y);
  }
  
  /* 
  function to create a ship and returns address of this new one
  */
  function createShip() external returns (address){
    Ship ship = new Ship(msg.sender);
    return address(ship);
  }
}
