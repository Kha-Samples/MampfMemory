package memory;

import haxe.Timer;
import kha.Configuration;
import kha.FontStyle;
import kha.Game;
import kha.Image;
import kha.Loader;
import kha.LoadingScreen;
import kha.Painter;
import kha.Random;

class Memory extends Game {
	private var back: Image;
	private var shadow: Image;
	private var cards: Array<Card>;
	private var dragger: FoodDragger;
	private var errors: Int = 0;
	private var healthErrors: Int = 0;
	private var round: Int = 0;
	
	public function new() {
		super("Memory", false);
	}
	
	override public function init(): Void {
		Configuration.setScreen(new LoadingScreen());
		Loader.the.loadRoom("memory", loadingFinished);
	}
	
	private var pairCount: Int;
	private var completeCount: Int;
	
	private function checkComplete(): Void {
		++completeCount;
		if (completeCount == pairCount) loadingFinished2();
	}
	
	private function loadingFinished(): Void {
		var xml = Xml.parse(Loader.the.getBlob("memory.xml").toString());
		var pairs = xml.firstElement().elementsNamed("Memory").next().elementsNamed("Pair");
		pairCount = 0;
		completeCount = 0;
		for (pair in pairs) {
			++pairCount;
		}
		pairs = xml.firstElement().elementsNamed("Memory").next().elementsNamed("Pair");
		for (pair in pairs) {
			var img = pair.elementsNamed("Image").next();
			var filename = img.firstChild().nodeValue;
			var name = filename.substr(0, filename.length - 4);
			Loader.the.loadImage(filename, function(image: Image) {
				Food.addImage(name, image);
				checkComplete();
			});
		}
	}
	
	private var rows: Int;
	private var columns: Int;
	private var foodCount: Int;
	
	private function loadingFinished2(): Void {	
		Random.init(Std.int(Timer.stamp() * 1000));
		back = Loader.the.getImage("memory/bg_pattern");
		shadow = Loader.the.getImage("memory/shadow");
		dragger = new FoodDragger();
		Food.cook();
		ClassPlate.init();
		cards = new Array<Card>();
		
		var xml = Xml.parse(Loader.the.getBlob("memory.xml").toString());
		var memoElement = xml.firstElement().elementsNamed("Memory").next();
		
		rows = Std.parseInt(memoElement.get("rows"));
		columns = Std.parseInt(memoElement.get("column"));
		foodCount = rows * columns;
		
		layCards();
		
		setInstance();
		Configuration.setScreen(this);
	}
	
	private function layCards(): Void {
		var bigFoodPile = Food.all.copy();
		var foodPile = new Array<Food>();
		
		for (i in 0...Std.int(foodCount / 2)) {
			var food = bigFoodPile[Random.getUpTo(bigFoodPile.length - 1)];
			bigFoodPile.remove(food);
			foodPile.push(food);
			foodPile.push(food);
		}
		
		for (xcount in 0...columns) {
			var x = 100 + xcount * width / columns;
			for (ycount in 0...rows) {
				var y = 100 + ycount * height / rows;
				var xx = x + Random.getUpTo(40) - 20;
				var yy = y + Random.getUpTo(40) - 20;
				var food = foodPile[Random.getUpTo(foodPile.length - 1)];
				foodPile.remove(food);
				cards.push(new Card(xx, yy, food));
				//cards.push(new Card(xx, yy, Food.all[0]));
			}
		}
	}
	
	private function reset(): Void {
		errors = 0;
		healthErrors = 0;
		round = 0;
		layCards();
	}
	
	override public function update(): Void {
		if (waiting > 0) {
			--waiting;
			if (waiting <= 0) {
				firstCard.click();
				secondCard.click();
				firstCard = null;
				secondCard = null;
			}
		}
		for (card in cards) card.update();
		dragger.update();
	}
	
	override public function render(painter: Painter): Void {
		var x = 0;
		while (x < width) {
			var y = 0;
			while (y < height) {
				painter.drawImage(back, x, y);
				y += back.getHeight();
			}
			x += back.getWidth();
		}
		painter.drawImage2(shadow, 0, 0, shadow.getWidth(), shadow.getHeight(), 0, 0, width, height);
		
		for (card in cards) card.render(painter);
		dragger.render(painter);
		if (gameover) {
			painter.setColor(255, 255, 255);
			var font = Loader.the.loadFont("Arial", new FontStyle(false, false, false), 55);
			painter.setFont(font);
			painter.drawString("Game Over", width / 2 - font.stringWidth("Game Over") / 2, height / 3 - font.getHeight() / 2);
			var score = pairCount * 10 - errors * 1 - healthErrors * 2;
			var scoreString = "Score: " + Std.string(score);
			painter.drawString(scoreString, width / 2 - font.stringWidth(scoreString) / 2, height / 2 - font.getHeight() / 2);
		}
	}
	
	var clickedCard: Card = null;
	var firstCard: Card = null;
	var secondCard: Card = null;
	var waiting: Int = 0;
	var dragging = false;
	var gameover = false;
	
	public function nextRound(): Void {
		if (dragging) {
			++round;
			if (round == pairCount) {
				gameover = true;
			}
		}
		dragging = false;
	}
	
	override public function mouseDown(x: Int, y: Int): Void {
		if (gameover) {
			reset();
			gameover = false;
			return;
		}
		if (dragging) {
			dragger.mouseDown(x, y);
			return;
		}
		if (waiting > 0) return;
		for (card in cards) {
			if (x >= card.x - Card.width / 2 && x <= card.x + Card.width / 2 && y >= card.y - Card.height / 2 && y <= card.y + Card.height / 2) {
				clickedCard = card;
				break;
			}
		}
	}
	
	override public function mouseUp(x: Int, y: Int): Void {
		if (gameover) return;
		if (dragging) {
			healthErrors += dragger.mouseUp(x, y);
			return;
		}
		if (waiting > 0) return;
		for (card in cards) {
			if (x >= card.x - Card.width / 2 && x <= card.x + Card.width / 2 && y >= card.y - Card.height / 2 && y <= card.y + Card.height / 2) {
				if (clickedCard == card) {
					card.click();
					clickedCard = null;
					
					if (firstCard == null) {
						firstCard = card;
					}
					else {
						if (firstCard.food == card.food) {
							cards.remove(firstCard);
							cards.remove(card);
							dragger.setCards(firstCard, card);
							firstCard = null;
							dragging = true;
						}
						else {
							secondCard = card;
							waiting = 80;
							++errors;
						}
					}
					break;
				}
			}
		}
	}
	
	override public function mouseMove(x: Int, y: Int): Void {
		if (gameover) return;
		if (dragging) {
			dragger.mouseMove(x, y);
			return;
		}
	}
}