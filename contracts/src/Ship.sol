// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "hardhat/console.sol";

contract Ship {
  address private owner;
  mapping(uint => mapping(uint => uint)) private map; // 0 : no informations ; 1 : my ship ; 2 : target fired ; 3 : ship allies ;
  uint private w;
  uint private h;
  uint private shipId = 0;
  uint private counter = 0;
  uint private availablePosition = 0;

  constructor(address o, uint idx){
    owner = o;
    shipId = idx;
  }

  // ----------------------- UTILS FUNCTIONS ---------------------

  /* 
  Function to return a random integer
  */
  function random() private returns (uint){
    counter+=1024;
    return uint(keccak256(abi.encode(owner,counter*shipId)));
  }

  /*
  Function to share a value of our map for the position (x,y)
  */
  function getValue(uint x, uint y) public view returns (uint){
    return map[x][y];
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

  // ----------------------- BASIS FUNCTIONS ---------------------

  /* 
  Function to update the position of the ship
  -->initial position can be impossible
  */
  function update(uint x, uint y) public{
    map[x][y] = 1;
    availablePosition = (w * h) - 1 ;
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
    availablePosition = availablePosition - 1;
    return (get_h,get_w);
  }

  /* 
  Function to select a position for the ship, this position is choosen randomly 
  This one may not be selected
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

  // ----------------------- COMMUNICATION FUNCTIONS ---------------------

  /*
  Function to communicate with an allie. Indeed, we get knowlodge from this one.
  This allie send the value of his map for the position (x,y).
  We can update our map.
  */
  function communicate(uint x, uint y, uint value) public{
    
    // the position of an allie
    if (value == 1){
      map[x][y] = 3;
      availablePosition = availablePosition - 1;
    }

    // the position of a fire of an allie
    if (value == 2 && map[x][y] == 0){
      map[x][y] = 2;
      availablePosition = availablePosition - 1;
    }
  }

  // ----------------------- CHANGE POSITION FUNCTION ---------------------

  /* 
  Method to update a new position for the ship
  */
  function newPlace(uint prev_x, uint prev_y, uint n_x, uint n_y) public{
    map[prev_x][prev_y] = 0;
    //console.log("new position (%s,%s)",n_x,n_y);
    if (map[n_x][n_y] != 0){
      availablePosition += 1;
    }
    map[n_x][n_y] = 1;
  }

  // ----------------------- RESET MAP FUNCTIONS ---------------------

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
    availablePosition = (h * w) - 1;
  }

  /*
  Method to check if the ship must to reset his map and reset it 
  */
  function checkReset(uint index) public{
    if (availablePosition == 0){
      //console.log("ship %s have to reset",index);
      reset();
    }
  }
}

