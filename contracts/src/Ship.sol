// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import 'hardhat/console.sol';

contract Ship {
  address owner;
  mapping(uint => mapping(uint => uint)) map; // 0 : no informations ; 1 : my ship ; target fired : miss ;
  uint w;
  uint h;
  uint counter = 0;

  constructor(address o){
    owner = o;
  }

  // todo maybe create a set a positions available et get a random value from this set ??

  /* 
  Function to return a random integer
  */
  function random() private returns (uint){
    counter += 1;
    return uint(keccak256(abi.encode(counter)));
  }

  /* 
  Function to update the position of the ship
  -->initial position can be impossible
  */
  function update(uint x, uint y) public{
    map[x][y] = 1;
  }

  /* Function to select a position to fire, 
  this position is choosen randomly if this one
  have not be slected
  Return this position
  */
  function fire() public returns (uint, uint){
    uint get_h = random() % h;
    uint get_w = random() % w;
    bool found = true;

    while(found){
      get_h = random() % h;
      get_w = random() % w;

      if(map[get_h][get_w] == 0){
        found = false;
      }
    }
    map[get_h][get_w] = 2;
    return (get_h,get_w);
  }

  /* Function to select a position for the ship, 
  this position is choosen randomly if this one
  have not be selected
  Return this position
  */
  function place(uint width, uint height) public returns (uint, uint){
    w = width;
    h = height;

    uint get_h = random() % h;
    uint get_w = random() % w;
    bool found = true;

    while(found){
      get_h = random() % h;
      get_w = random() % w;

      if(map[get_h][get_w] == 0){
        found = false;
      }
    }

    return (get_h,get_w);
  }
}

