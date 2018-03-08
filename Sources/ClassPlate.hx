package;

import kha.Assets;
import kha.graphics2.Graphics;
import kha.Image;
import kha.math.Vector2;

class ClassPlate {
	private static var width = 200;
	private static var height = 200;
	private static var green: Image;
	private static var yellow: Image;
	private static var red: Image;
	private static var neutral: Image;
	private static var right: Image;
	private static var wrong: Image;
	
	private var color: MampfColor;
	private var shown = false;
	private var correct = false;
	public var pos: Vector2;
	
	public static function init(): Void {
		green   = Assets.images.class_green;
		yellow  = Assets.images.class_yellow;
		red     = Assets.images.class_red;
		neutral = Assets.images.class_neutral;
		right   = Assets.images.class_right;
		wrong   = Assets.images.class_wrong;
	}
	
	public function new(color: MampfColor) {
		this.color = color;
		pos = new Vector2();
	}
	
	public function getColor(): MampfColor {
		return color;
	}
	
	public function setCorrect(correct: Bool) {
		this.correct = correct;
	}
	
	public function update(): Void {
		
	}
	
	public function render(g: Graphics): Void {
		var image: Image = null;
		switch (color) {
			case MampfColor.Green:
				image = green;
			case MampfColor.Yellow:
				image = yellow;
			case MampfColor.Red:
				image = red;
		}
		g.drawScaledSubImage(image, 0, 0, image.width, image.height, pos.x - width / 2, pos.y - height / 2, width, height);
		if (shown) {
			if (correct) g.drawScaledSubImage(right, 0, 0, right.width, right.height, pos.x - width / 2, pos.y - height / 2, width, height);
			else g.drawScaledSubImage(wrong, 0, 0, wrong.width, wrong.height, pos.x - width / 2, pos.y - height / 2, width, height);
		}
		else g.drawScaledSubImage(neutral, 0, 0, neutral.width, neutral.height, pos.x - width / 2, pos.y - height / 2, width, height);
	}
	
	public function show(): Void {
		shown = true;
	}
	
	public function hide(): Void {
		shown = false;
	}
}
