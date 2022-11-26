// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "hardhat/console.sol";

contract Ship {
  address private owner;
  mapping(uint => mapping(uint => uint)) private map; // 0 : no informations ; 1 : my ship ; target fired : miss ;
  uint private w;
  uint private h;
  uint private shipId = 0;
  uint private counter = 0;

  constructor(address o, uint idx){
    owner = o;
    shipId = idx;
  }

  // todo maybe create a set a positions available et get a random value from this set ??

  /* 
  Function to return a random integer
  */
  function random() private returns (uint){
    counter+=1024;
    return uint(keccak256(abi.encode(owner,counter*shipId)));
  }

  /*
  Function to communicate with an allie. Indeed, we get knowlodge from this one.
  This allie send the value of his map for the position (x,y).
  We can update our map.
  */
  function communicate(uint x, uint y, uint value) public{
    if (value == 1){
      map[x][y] = 3;
    }
    if (value == 2 && map[x][y] == 0){
      map[x][y] = 2;
    }
  }

  /*
  Function to share a value of our map for the position (x,y)
  */
  function getValue(uint x, uint y) public view returns (uint){
    return map[x][y];
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
    uint get_h;
    uint get_w;
    bool isAlreadyTargeted = true;

    while(isAlreadyTargeted){
      get_h = random() % h;
      get_w = random() % w;

      if(map[get_h][get_w] == 0){
        isAlreadyTargeted = false;
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

      if(map[get_h][get_w] == 0 || map[get_h][get_w] == 2){
        found = false;
      }
    }

    return (get_h,get_w);
  }

  /*
  Method to print the map of the ship
  */
  function printMap() public view{
    for (uint x; x<h; x+=1){
      for (uint y; y<w; y+=1){
        console.log("(%s,%s)=%s",x,y,map[x][y]);
      }
    }
  }

  /*
  Method to inform if we have to reset the ship's map,
  --> search if there is a empty case (case == 0)
  Return a bool --> True if there is any empty case
  */
  function haveToReset() private view returns (bool){
    for (uint x; x<h; x+=1){
      for (uint y; y<w; y+=1){
        if (map[x][y] == 0){
          return false;
        }
      }
    }
    return true;
  }

  /* 
  Metho to reset the ship's map except his position
  */
  function reset() private{
    for (uint x; x<h; x+=1){
      for (uint y; y<w; y+=1){
        if (map[x][y] != 1){
          map[x][y] = 0;
        }
      }
    }
  }

  /*
  Method to check if the ship must to reset his map and reset it 
  */
  function checkReset(uint index) public{
    if (haveToReset()){
      console.log("ship %s have to reset",index);
      reset();
    }
  }

  /* 
  Method to update a new position for the ship
  */
  function newPlace(uint n_x, uint n_y) public{
    for (uint x; x<h; x+=1){
      for (uint y; y<w; y+=1){
        map[x][y] = 0;
      }
    }
    console.log("new position (%s,%s)",n_x,n_y);
    map[n_x][n_y] = 1;
  }
}

