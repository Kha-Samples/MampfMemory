package;

import haxe.Timer;
import kha.Assets;
import kha.Color;
import kha.Framebuffer;
import kha.Image;
import kha.input.Mouse;
import kha.math.Random;
import kha.Scaler;
import kha.Scheduler;
import kha.ScreenCanvas;
import kha.System;

class Memory {
	private var backbuffer: Image;
	private var back: Image;
	private var shadow: Image;
	private var cards: Array<Card>;
	private var dragger: FoodDragger;
	private var errors: Int = 0;
	private var healthErrors: Int = 0;
	private var round: Int = 0;
	private static inline var width = 1024;
	private static inline var height = 768;
	
	public function new() {
		System.init({width: width, height: height, title: "Mampf Memory"}, function () {
			backbuffer = Image.createRenderTarget(width, height);
			Assets.loadEverything(loadingFinished);
		});
	}
	
	private var pairCount: Int;
	
	private function loadingFinished(): Void {
		var xml = Xml.parse(Assets.blobs.memory_xml.toString());
		var pairs = xml.firstElement().elementsNamed("Memory").next().elementsNamed("Pair");

		pairCount = 0;
		for (pair in pairs) {
			++pairCount;
		}
		
		++pairCount;
		Card.setBack(Assets.images.card_back);
		
		pairs = xml.firstElement().elementsNamed("Memory").next().elementsNamed("Pair");
		for (pair in pairs) {
			var img = pair.elementsNamed("Image").next();
			var name = img.firstChild().nodeValue;
			Food.addImage(name, Assets.images.get(name));
		}
		loadingFinished2();
	}
	
	private var rows: Int;
	private var columns: Int;
	private var foodCount: Int;
	
	private function loadingFinished2(): Void {	
		Random.init(Std.int(Timer.stamp() * 1000));
		back = Assets.images.bg_pattern;
		shadow = Assets.images.shadow;
		dragger = new FoodDragger(this);
		Food.cook();
		ClassPlate.init();
		cards = new Array<Card>();
		
		var xml = Xml.parse(Assets.blobs.memory_xml.toString());
		var memoElement = xml.firstElement().elementsNamed("Memory").next();
		
		rows = Std.parseInt(memoElement.get("rows"));
		columns = Std.parseInt(memoElement.get("column"));
		foodCount = rows * columns;
		
		layCards();
		
		System.notifyOnRender(render);
		Scheduler.addTimeTask(update, 0, 1 / 60);
		Mouse.get().notify(mouseDown, mouseUp, mouseMove, null);
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
			var x = 100 + xcount * System.windowWidth() / columns;
			for (ycount in 0...rows) {
				var y = 100 + ycount * System.windowHeight() / rows;
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
	
	function update(): Void {
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
	
	function render(frame: Framebuffer): Void {
		var g = backbuffer.g2;
		g.begin();
		g.color = Color.White;
		var x = 0;
		while (x < width) {
			var y = 0;
			while (y < height) {
				g.drawImage(back, x, y);
				y += back.height;
			}
			x += back.width;
		}
		g.drawScaledSubImage(shadow, 0, 0, shadow.width, shadow.height, 0, 0, width, height);
		
		for (card in cards) card.render(g);
		dragger.render(g);
		if (gameover) {
			g.color = Color.White;
			var font = Assets.fonts.arial;
			var fontSize = 55;
			g.font = font;
			g.fontSize = fontSize;
			g.drawString("Game Over", width / 2 - font.width(fontSize, "Game Over") / 2, height / 3 - font.height(fontSize) / 2);
			var score = pairCount * 10 - errors * 1 - healthErrors * 2;
			var scoreString = "Score: " + Std.string(score);
			g.drawString(scoreString, width / 2 - font.width(fontSize, scoreString) / 2, height / 2 - font.height(fontSize) / 2);
		}
		g.end();
		
		frame.g2.begin();
		Scaler.scale(backbuffer, frame, System.screenRotation);
		frame.g2.end();
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
			if (round == pairCount - 1) {
				gameover = true;
			}
		}
		dragging = false;
	}
	
	function mouseDown(button: Int, ox: Int, oy: Int): Void {
		if (gameover) {
			reset();
			gameover = false;
			return;
		}
		var x = Scaler.transformX(ox, oy, backbuffer, ScreenCanvas.the, System.screenRotation);
		var y = Scaler.transformY(ox, oy, backbuffer, ScreenCanvas.the, System.screenRotation);
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
	
	function mouseUp(button: Int, ox: Int, oy: Int): Void {
		if (gameover) return;
		var x = Scaler.transformX(ox, oy, backbuffer, ScreenCanvas.the, System.screenRotation);
		var y = Scaler.transformY(ox, oy, backbuffer, ScreenCanvas.the, System.screenRotation);
		if (dragging) {
			healthErrors += dragger.mouseUp(x, y);
			return;
		}
		if (waiting > 0) return;
		for (card in cards) {
			if (x >= card.x - Card.width / 2 && x <= card.x + Card.width / 2 && y >= card.y - Card.height / 2 && y <= card.y + Card.height / 2) {
				if (clickedCard == card && clickedCard != firstCard) {
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
	
	function mouseMove(x: Int, y: Int, mx: Int, my: Int): Void {
		if (gameover) return;
		if (dragging) {
			dragger.mouseMove(Scaler.transformX(x, y, backbuffer, ScreenCanvas.the, System.screenRotation), Scaler.transformY(x, y, backbuffer, ScreenCanvas.the, System.screenRotation));
			return;
		}
	}
}
