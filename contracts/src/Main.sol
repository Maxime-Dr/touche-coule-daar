// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "./Ship.sol";
import "hardhat/console.sol";

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
  mapping(uint => uint) private turns; //store the autorization to change positions

  event Size(uint width, uint height);
  event Touched(uint ship, uint x, uint y);
  event Registered(
    uint indexed index,
    address indexed owner,
    uint x,
    uint y
  );
  event Moved(
    uint ship, 
    uint prev_x, 
    uint prev_y,
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

  function register() external {
    address ship = address(new Ship(msg.sender, index)); // get address of the new ship
    require(count[msg.sender] < 2, "Only two ships");
    require(!used[ship], "Ship alread on the board");
    require(index <= game.height * game.width, "Too much ship on board");
    count[msg.sender] += 1;
    turns[index] = 5; // a ship can change position every 5 turns
    ships[index] = ship;
    owners[index] = msg.sender;
    (uint x, uint y) = placeShip(index);
    //console.log("Register --> id:%s x:%s, y%s",index,x,y);
    Ship(ships[index]).update(x, y);
    emit Registered(index, msg.sender, x, y);
    used[ship] = true;
    index += 1;
  }

  function turn() external {

    bool[] memory touched = new bool[](index);
    for (uint i = 1; i < index; i++) {
      if (game.xs[i] < 0) continue;
      turns[i] = turns[i] - 1;
      
      Ship ship = Ship(ships[i]);

      //reset map of the ship if the map is full
      ship.checkReset(i);

      // fire
      (uint x, uint y) = ship.fire();
      //console.log("FIRE --> id:%s x:%s, y%s",i,x,y);
      
      // check if we touched someone
      if (game.board[x][y] > 0) {
        //console.log("TOUCHE");
        touched[game.board[x][y]] = true;
      }
    }

    // eliminate ships touched
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
  //  function createShip() external returns (address){
  //    Ship ship = new Ship(msg.sender, index);
  //    return address(ship);
   // }

  /*
  function to check if the player can change position of this ship
  at least 1
  Return a bool
  */
  function canChangePosition() private view returns (bool b){
    for (uint i = 0; i < index; i++) {
      if (game.xs[i] < 0) continue;
      if (turns[i] <= 0 && owners[i] == msg.sender){
        return true;
      }
    }
    return false;
  }

  /* 
  function to change the position of ship of the playeer
  */
  function changePosition() external{
    require(canChangePosition(),"you cannot change positions");
    for (uint i = 0; i < index; i++) {
      if (game.xs[i] < 0) continue;
      
      // find a ship which can move
      if (turns[i] <= 0 && owners[i] == msg.sender){
        turns[i] = 5; // reset his counter
        Ship ship = Ship(ships[i]);
        uint prev_x = uint(game.xs[i]); // store previous valeur of x
        uint prev_y = uint(game.ys[i]); // store previous valeur of y
        game.board[uint(game.xs[i])][uint(game.ys[i])] = 0; // delete the position in the board
        
        // get a new position
        (uint x, uint y) = ship.place(game.width, game.height);
        bool invalid = true;
        while (invalid) {
          if (game.board[x][y] == 0) {
            game.board[x][y] = i;
            game.xs[i] = int(x);
            game.ys[i] = int(y);
            invalid = false;
          } else {
            uint newPlace = (x * game.width) + y + 1;
            x = newPlace % game.width;
            y = newPlace / game.width % game.height;
          }
        }
        ship.newPlace(prev_x,prev_y,x, y); // update the map of the ship
        emit Moved(uint(i), prev_x, prev_y, owners[i], uint(x), uint(y)); // to update the frontend
      }
    }
  }

  /*
  function return the number of ships of a player in play
  */ 
  function numberShipInPlay() private view returns (uint){
    uint counter_ship = 0;
    for (uint i = 0; i < index; i++) {
      if (game.xs[i] < 0) continue;
      
      // get ships of the player
      if (owners[i] == msg.sender){
        counter_ship += 1;
      }
    }
    return counter_ship;
  }

  /*
  Function to communicate with allies ships in order to 
  get their knowledgments (their maps)
  */
  function communication() external{
    require(count[msg.sender] > 0, "do not possess ships");
    require(numberShipInPlay() >= 2, "need at least 2 ships");
    uint[] memory ships_of_owner = new uint[](index);
    uint counter = 0;
    
    // search allies
    for (uint i = 0; i < index; i++) {
      if (game.xs[i] < 0) continue;
      
      // get ships of the player
      if (owners[i] == msg.sender){
        ships_of_owner[counter] = i;
        counter += 1;
      }
    }

    // communication between allies
    for (uint i = 0; i < counter; i++) {
      Ship ship = Ship(ships[ships_of_owner[i]]); // get the ship at the index ships_of_owner[i]
      for (uint j = 0; j < counter; j++) {
        if (i != j){
          Ship allie = Ship(ships[ships_of_owner[j]]); // get the ship at the index ships_of_owner[j]
          // get information of all his map
          for (uint x; x<game.height; x+=1){
            for (uint y; y<game.width; y+=1){
              uint value = allie.getValue(x,y); // get value for the position (x,y)
              ship.communicate(x,y,value); // communicate --> update ship's map
            }
          }
        }
      }

      //reset map of the ship if the map is full
      ship.checkReset(i);
    }
  }
}
