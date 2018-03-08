package;

import kha.Assets;
import kha.Image;

class Food {
	public static var all: Array<Food>;
	private static var foodImages: Map<String, Image> = new Map<String, Image>();
	public var image: Image;
	public var color: MampfColor;
	
	public function new(image: Image, color: MampfColor) {
		this.image = image;
		this.color = color;
	}
	
	public static function addImage(name: String, image: Image): Void {
		foodImages.set(name, image);
	}
	
	public static function cook(): Void {
		all = new Array<Food>();
		var xml = Xml.parse(Assets.blobs.memory_xml.toString());
		for (pair in xml.firstElement().elementsNamed("Memory").next().elementsNamed("Pair")) {
			var img = pair.elementsNamed("Image").next();
			var name = img.firstChild().nodeValue;
			var health = pair.elementsNamed("Health").next().firstChild().nodeValue;
			var color: MampfColor;
			if (health == "Green") color = MampfColor.Green;
			else if (health == "Yellow") color = MampfColor.Yellow;
			else color = MampfColor.Red;
			add(name, color);
		}
		/*
		add("avokado",      MampfColor.Green);
		add("cake",         MampfColor.Red);
		add("cheese",       MampfColor.Yellow);
		add("cheeseburger", MampfColor.Red);
		add("chips",        MampfColor.Red);
		add("cucumber",     MampfColor.Green);
		add("donut",        MampfColor.Red);
		add("friedegg",     MampfColor.Red);
		add("fries",        MampfColor.Red);
		add("mango",        MampfColor.Green);
		add("peas",         MampfColor.Green);
		add("pizza",        MampfColor.Red);
		add("salad",        MampfColor.Green);
		add("steak",        MampfColor.Red);
		add("toast",        MampfColor.Red);
		*/
	}
	
	private static function add(image: String, color: MampfColor): Void {
		all.push(new Food(foodImages.get(image), color));
	}
}
