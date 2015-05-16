package {
	import flash.display.*;
	import flash.events.*;
	import flash.text.*;
	
	public class CollapsingBlocks extends MovieClip {
		
		// constants
		static const spacing:Number = 32;
		static const offsetX:Number = 34;
		static const offsetY:Number = 60;
		static const numCols:int = 16;
		static const numRows:int = 10;
		static const moveStep:int = 4;
		
		// game grid and mode
		private var blocks:Array; // grid of blocks
		private var gameSprite:Sprite;
		private var gameScore:int;
		private var checkColumns:Boolean;
		
		// set up blocks and start game
		public function startCollapsingBlocks() {
			
			// create blocks array
			blocks = new Array();
			for(var cols:int=0;cols<numCols;cols++) {
				blocks.push(new Array());
			}
			
			// create game sprite and add blocks to sprite and array
			gameSprite = new Sprite();
			for(var col:int=0;col<numCols;col++) {
				for(var row:int=0;row<numRows;row++) {
					addBlock(col,row);
				}
			}
			addChild(gameSprite);
		
			// set starting values
			checkColumns = false;
			gameScore = 0;
			
			// begin to watch for moving blocks
			addEventListener(Event.ENTER_FRAME,moveBlocks);
		}
		
		// create a random block, add to sprite and array
		public function addBlock(col,row:int) {
			
			// create object and set location and type
			var newBlock:Block = new Block();
			newBlock.col = col;
			newBlock.row = row;
			newBlock.type = Math.ceil(Math.random()*4);
			
			/// position on screen
			newBlock.x = col*spacing+offsetX;
			newBlock.y = row*spacing+offsetY;
			newBlock.gotoAndStop(newBlock.type);
			gameSprite.addChild(newBlock);
			
			// add to array
			blocks[col][row] = newBlock;
			
			// set mouse event listener
			newBlock.addEventListener(MouseEvent.CLICK,clickBlock);
		}
		
		// player clicks on a block
		public function clickBlock(event:MouseEvent) {
			var block:Block = Block(event.currentTarget);
			var pointsScored:int = findAndRemoveMatches(block);
			
			if (pointsScored > 0) {
				var pb = new PointBurst(this,pointsScored,mouseX,mouseY);
			}
		}

		// gets matches and removes them, applies points
		public function findAndRemoveMatches(block:Block):int {
			
			// get the block type
			var type:int = block.type;
			
			// start recursive search for all blocks that match
			var matchList:Array = testBlock(block.col, block.row, type);
			
			// see if enough match
			if (matchList.length > 1) {
				
				// remove these, and allow ones above them to drop
				for(var i=0;i<matchList.length;i++) {
					gameSprite.removeChild(matchList[i]);
					affectAbove(matchList[i]);
				}
				
				// remember to check for empty columns when drops are done
				checkColumns = true;
				
				// add score based on the number of blocks and return that score
				var pointsScored:int = matchList.length * matchList.length;
				addScore(pointsScored);
				return pointsScored;
			
			} else {
				// not enough match, so restore original block type
				block.type = type;
			}
			
			// no points scored
			return 0;
		}
		
		// recursively look for matches in 4 directions
		public function testBlock(col,row,type) {
			
			// start with empty array
			var testList:Array = new Array();
		
			// does the block exist, or has this block already been found?
			if (getBlockType(col,row) == 0) return testList;
			
			// is the block the right type?
			if (blocks[col][row].type == type)  {
				
				// add block to array and zero it out
				testList.push(blocks[col][row]);
				blocks[col][row].type = 0;
				
				// test in all directions from here
				testList = testList.concat(testBlock(col+1, row, type));
				testList = testList.concat(testBlock(col-1, row, type));
				testList = testList.concat(testBlock(col, row+1, type));
				testList = testList.concat(testBlock(col, row-1, type));
			}
			
			// return results
			return testList;
		}
		
		public function getBlockType(col,row) {
			// first check to see if the location is within limits
			if ((col < 0) || (col >= numCols)) return 0;
			if ((row < 0) || (row >= numRows)) return 0;
			
			// does block exist?
			if (blocks[col][row] == null) return 0;
			
			// block exists, so return type
			return blocks[col][row].type;
			
		}
		
		// if any blocks are out of place, move them a step closer to being in place
		// happens when blocks are dropping, or moving to left
		public function moveBlocks(event:Event) {
			var madeMove:Boolean = false;
			for(var row:int=0;row<numRows;row++) {
				for(var col:int=0;col<numCols;col++) {
					if (blocks[col][row] != null) {
						
						// needs to move down
						if (blocks[col][row].y < blocks[col][row].row*spacing+offsetY) {
							blocks[col][row].y += moveStep;
							madeMove = true;
							
						// needs to move left
						} else if (blocks[col][row].x > blocks[col][row].col*spacing+offsetX) {
							blocks[col][row].x -= moveStep;
							madeMove = true;
						}
					}
				}
			}
			
			// everything settled, so time to check for empty columns
			if ((!madeMove) && (checkColumns)) {
				checkColumns = false;
				checkForEmptyColumns();
			}
		}
				
		
		// tell all blocks above this one to move down
		public function affectAbove(block:Block) {
			
			// remove this block
			blocks[block.col][block.row] = null;
			
			// check blocks above and move them down
			for(var row:int=block.row-1;row>=0;row--) {
				if (blocks[block.col][row] != null) {
					blocks[block.col][row].row++;
					blocks[block.col][row+1] = blocks[block.col][row];
					blocks[block.col][row] = null;
				}
			}
		}
		
		// look at each column to see if one is empty
		public function checkForEmptyColumns() {
			
			// assume no column found
			var foundEmpty:Boolean = false;
			var blocksToMove:int = 0;
				
			// loop through each column, left to right
			for(var col:int=0;col<numCols;col++) {
				
				// if no empty found yet
				if (!foundEmpty) {
					
					// see if bottom block is gone
					if (blocks[col][numRows-1] == null) {
						
						// this column is empty!
						foundEmpty = true;
						
						// remember to check for empty columns again
						checkColumns = true;
					}
					
				// empty column found before, so this one must move over
				} else {
					
					// loop through blocks and set each to move left
				for(var row:int=0;row<numRows;row++) {
						if (blocks[col][row] != null) {
							blocks[col][row].col--;
							blocks[col-1][row] = blocks[col][row];
							blocks[col][row] = null;
							blocksToMove++;
						}
					}
				}
			}
			
			// didn't move any blocks, check to see if the game is over
			if (blocksToMove == 0) {
				checkColumns = false;
				checkForGameOver();
			}
		}
		
		// see if any more moves possible
		public function checkForGameOver() {
			
			// loop through all blocks
			for(var col=0;col<numCols;col++) {
				for(var row=0;row<numRows;row++) {
					
					// if this block is there, and matches to the right
					// or below, then there are moves possible
					var block:int = getBlockType(col,row);
					if (block == 0) continue;
					if (block == getBlockType(col+1,row)) return;
					if (block == getBlockType(col,row+1)) return;
				}
			}
			
			// no possible moves found, game must be over
			endGame();
		}
		
		public function endGame() {
			// move to back
			setChildIndex(gameSprite,0);
			// go to end game
			gotoAndStop("gameover");
		}
		
		// add to the score and display it
		public function addScore(numPoints:int) {
			gameScore += numPoints;
			scoreDisplay.text = String(gameScore);
		}
		
		public function cleanUp() {
			blocks = null;
			removeChild(gameSprite);
			gameSprite = null;
			removeEventListener(Event.ENTER_FRAME,moveBlocks);
			scoreDisplay.text = "0";
		}
	}
}
