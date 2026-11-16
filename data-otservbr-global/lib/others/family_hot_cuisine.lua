-- Gaia Family server: Hot Cuisine Quest review (2026-11-16).
--
-- Ours, not upstream. Asked by Rodrigo: review the quest and Jean Pierre's dialogue against our
-- TibiaWiki BR backup (RLGaia/tibiawiki-backup) and TibiaWiki EN, and remove the yearly limit:
-- dishes can be cooked whenever he wants, just by bringing the ingredients.
--
-- Real Tibia: Jean Pierre is there only in August; after his course each dish can be cooked
-- again once a year. Here (Family.hotCuisineAnytime):
--   * he is home all year and greets every day;
--   * the course is the same: dishes 1-10 with "recipe", then the menu (11-15) with "menu", in
--     order; a dish not taught yet is not cooked;
--   * a dish already taught can be cooked again at any time, as often as wanted: name it, say yes
--     and hand over the ingredients.
-- Fixes of the upstream NPC (data-otservbr-global/npc/jean_pierre.lua), Family.hotCuisine:
--   * he checked the ingredients of the next course dish, not of the dish named (a recook took the
--     wrong items or failed with a Lua error after the course), and a recook moved the course back;
--   * any dish name worked before it was taught (saying "sweet mangonaise elixir" skipped the
--     whole course);
--   * "recipes" and "demonic candy balls" (the words he highlights) were not understood;
--   * the Carrot Cake gave a solstice tree (id 10000) instead of a carrot cake (9087);
--   * Demonic Candy Balls: 5 per cooking (BR item page "5 unidades"; upstream 1);
--   * the level 35 rule of the apprentice talk (EN line);
--   * the 15th dish, Zaoan Sauce (Monk update 15.00; BR lines, EN ingredients), was missing;
--   * the quest log skipped the Coconut Shrimp Bake state and had no Zaoan Sauce;
--   * Cookbook II (chest at 33064,32529,5 on our map) opened after dish 10 like Cookbook I; now
--     after the Sweet Mangonaise Elixir (CookbookDoor2);
--   * the achievement Culinary Master (cook each of the 14 dishes of 8.6 twice, EN) was never given.
-- Lines are from TibiaWiki EN/BR unless marked "ours".
-- Switches: Family.hotCuisine (false = upstream NPC code), Family.hotCuisineAnytime (false =
-- August only and each dish once per year, as in Tibia).

Family = Family or {}
Family.hotCuisine = true
Family.hotCuisineAnytime = true

FamilyHotCuisine = {}
local H = FamilyHotCuisine
H.kvScope = "family-hot-cuisine"
H.level = 35
H.achievement = "Culinary Master"
H.achievementDishes = 14 -- the dishes of 8.6; Zaoan Sauce came later

local VIAL = 2874
-- server fluid ids (items.xml): water 1, wine 2, beer 3, milk 9, coconut milk 15, mead 16
local FLUID_NAMES = { [1] = "water", [2] = "wine", [3] = "beer", [9] = "milk", [15] = "coconut milk", [16] = "mead" }

-- ingredients: { item id, count, fluid } (positional on purpose: tools/family/market/quest_items.py
-- must not take every ingredient for a quest item)
H.dishes = {
	{
		name = "Rotworm Stew",
		words = { "rotworm stew" },
		reward = 9079,
		ingredients = { { 3577, 2 }, { 8010, 20 }, { 8015, 1 }, { 8197, 1 }, { 3603, 5 }, { VIAL, 2, 3 } },
		intro = {
			"The first dish we are going to prepare together is called {Rotworm Stew}. Now, don't be scared off. Of course we won't eat those nasty and dirty earth-crawlers! ...",
			"The name is just for the effect it has on people. <winks> Bring me the following ingredients and I'll show you how it's done. ...",
			"Two pieces of meat, two vials of beer, twenty potatoes, one onion, one bulb of garlic and five ounces of flour. Make sure that the ingredients are fresh and smell good.",
		},
		question = "Did you gather all necessary ingredients to cook Rotworm Stew with me?",
		cook = {
			"Aah, so let's see! <prepares the food quickly while he explains it to you> We cook the meat in a large pot together with the chopped onion until it's separated from the bones. Now we also have a fine meat broth! ...",
			"Cut the potatoes into small pieces and add them to the pot. Add some flour to thicken the stew. Finally, spice it up with some garlic and add beer for the typical dwarvish taste! ...",
			"And voilà, we're done. I developed this recipe while talking to Maryza in the Jolly Axeman. She said to eat it when one's health is low. Enjoy!",
		},
	},
	{
		name = "Hydra Tongue Salad",
		words = { "hydra tongue salad", "hydra tongue" },
		reward = 9080,
		ingredients = { { 7250, 2 }, { 3596, 2 }, { 8014, 1 }, { 3606, 2 }, { 3741, 1 }, { VIAL, 1, 2 } },
		intro = {
			"The next dish we are going to prepare together is called {Hydra Tongue Salad}. The common hydra tongue is a pest plant with an surprisingly aromatic taste. ...",
			"We'll add some other vegetables and spices for the delicate and distinctive taste. Bring me the following ingredients and I'll show you how it's done. ...",
			"Two hydra tongue plants, two tomatoes, one cucumber, two eggs, one troll green and one vial of wine.",
		},
		question = "Did you gather all necessary ingredients to prepare a Hydra Tongue Salad with me?",
		cook = {
			"Okay, here we go! <cuts the ingredients so fast that his hands seem almost blurry> This one is easy, just chop the hydra tongues, tomatoes and cucumber into tiny pieces. ...",
			"Now for the sauce - our base is wine, in which we mix the raw eggs until it got a nice smooth consistency. Add grinded troll green, whose flavour is quite similar to basil and shake the sauce in a mug. ...",
			"Pour it over the salad, and voilà, we're done! This is a Venorean recipe and very tasty. I recommend eating it when you're suffering from some kind of dangerous condition. Enjoy!",
		},
	},
	{
		name = "Roasted Dragon Wings",
		words = { "roasted dragon wings", "dragon wings" },
		reward = 9081,
		ingredients = { { 4363, 1 }, { 8016, 3 }, { 3602, 5 }, { 3606, 2 }, { 3739, 1 }, { 3724, 5 } },
		intro = {
			"The next dish we are going to prepare together is called {Roasted Dragon Wings}. Oh, don't give me that look! Of course you don't have to bring a whole dragon up here. ...",
			"The 'dragon' part derives from the fiery afterburn of this meal, but the wings we use are much smaller, though similar in shape. Bring me the following ingredients and I'll show you how it's done. ...",
			"One fresh dead bat, three jalapeño peppers, five brown breads, two eggs, one powder herb and five red mushrooms.",
		},
		question = "Did you gather all necessary ingredients to prepare Roasted Dragon Wings with me?",
		cook = {
			"Let's get started! <starts grinding and chopping at amazing speed> The trick with this one is the crunchy crust around the wings. ...",
			"First, we grate the dry brown bread into very small crumbs and mix that with the two eggs. Add grinded peppers for the spicy taste and the powder herb for a hint of curry flavour. ...",
			"Carefully separate the bat wings, clean them of any possible hairs and coat them in our mixture. Roast them in a pan together with sliced mushrooms and serve. ...",
			"Voilà, we're done! This recipe is from the area around Thais and should help you protect yourself in your battles. Enjoy!",
		},
	},
	{
		name = "Tropical Fried Terrorbird",
		words = { "tropical fried terrorbird", "terrorbird" },
		reward = 9082,
		ingredients = { { 4330, 1 }, { 8013, 2 }, { 3586, 2 }, { 5096, 2 }, { VIAL, 2, 15 }, { 3735, 1 } },
		intro = {
			"The next dish we are going to prepare together is called {Tropical Fried Terrorbird}. You might have guessed it, we're not going to use a terrorbird. But! ...",
			"The dish is quite fried and tropical. Bring me the following ingredients and we're going to prepare it: One fresh dead chicken, two lemons, two oranges, two mangos, one stone herb and two vials of coconut milk.",
		},
		question = "Did you gather all necessary ingredients to prepare a Tropical Fried Terrorbird with me?",
		cook = {
			"This is a recipe right from the jungles of Tiquanda! <grinds and chops during his talk> Grind the stone herb and mix it with the coconut milk, then bathe the chicken in it for a while. ...",
			"In the meantime, peel the oranges and mangos, chop them into pieces and add them to the mix. Take the chicken out of its bath and fry it, preferably over open fire. ...",
			"Take the fruits out of the spicy coconut milk and heat them on an oven. Once the chicken is fried, add the fruits and spray some squeezed lemon over it. ...",
			"Voilà, we're done! They say that this dish has magical abilities and can awaken secret powers in you during your battles. Enjoy!",
		},
	},
	{
		name = "Banana Chocolate Shake",
		words = { "banana chocolate shake", "chocolate shake" },
		reward = 9083,
		ingredients = { { 6574, 1 }, { 6393, 1 }, { 3587, 2 }, { VIAL, 2, 9 }, { 3738, 1 }, { 3736, 1 } },
		intro = {
			"The next dish we are going to prepare together is called {Banana Chocolate Shake}. After all those spicy dishes you should treat your guests with a sweet surprise. ...",
			"Bring me the following ingredients and we'll make one hell of a drink: one bar of chocolate, one cream cake, two bananas, two vials of milk, one sling herb and one star herb.",
		},
		question = "Did you gather all necessary ingredients to make a Banana Chocolate Shake with me?",
		cook = {
			"Great! Let's get it done! <mixes and shakes faster than any human could> An easy one again, but you'll get right into holiday mood, like the Meriana beach dwellers I got that recipe from. ...",
			"Melt the chocolate in a hot-water bath and add the grinded herbs - did you know, those herbs have a flavour like cinnamon and vanilla, yummy! Keep at gentle heat and add the milk. ...",
			"Mash the banana and stir it really well into the chocolate-milk mixture. Gosh, do you smell that? Pure goodness! Now finally, we take just a bit of the creamcake and fold it in. ...",
			"Voilà, we're done! To be honest, I don't know what this drink does, but at least it makes me really happy. Drink together with a loved one and enjoy!",
		},
	},
	{
		name = "Veggie Casserole",
		words = { "veggie casserole", "casserole" },
		reward = 9084,
		ingredients = { { 3595, 2 }, { 3596, 2 }, { 3597, 2 }, { 8014, 2 }, { 8015, 1 }, { 8197, 1 }, { 3607, 1 }, { 3723, 20 }, { 3725, 5 } },
		intro = {
			"The next dish we are going to prepare together is called {Veggie Casserole}. This one is going to be your masterpiece so far, I'm telling you. ...",
			"It's also quite healthy! - Well, that's what I keep telling me when I eat the third serving, hehehe. Bring me the following ingredients and I'll show you how it's done. ...",
			"Two carrots, two tomatoes, two corncobs, two cucumbers, one onion, one bulb of garlic, one piece of cheese, twenty white mushrooms and five brown mushrooms.",
		},
		question = "Did you gather all necessary ingredients to cook a Veggie Casserole with me?",
		cook = {
			"So let's start! <rubs hands together and chops the vegetables> This is a dish especially famous in the area around Ab'Dendriel! Chop the onions into little cubes and sweat them in a pan until they are glassy. ...",
			"Add garlic and mushrooms and fry gently until the mushrooms have shrunk up. Now, we add the peeled tomatoes and corn and have it all nicely cook together. ...",
			"Put in carrot pieces and cucumber at the very end, so they will stay crisp! Finally put the cheese over it like a little blanket have it melt on the oven until it's slightly brownish. ...",
			"And voilà, we're done! This dish will help you in your battles and supply you with enough power to hit really hard! Enjoy!",
		},
	},
	{
		name = "Filled Jalapeño Peppers",
		listName = "Filled Jalapeno Peppers",
		words = { "filled jalapeno peppers", "filled", "jalapeno", "peppers" },
		reward = 9085,
		ingredients = { { 8016, 10 }, { 3607, 2 }, { 3741, 1 }, { 3740, 1 }, { VIAL, 1, 16 }, { 3606, 2 } },
		intro = {
			"The next dish we are going to prepare together is called {Filled Jalapeño Peppers}. It's a great snack and quite spicy, for those who like it hot. ...",
			"Bring me the following ingredients and I'll show you how it's done: Ten jalapeño peppers, two pieces of cheese, one troll green, one shadow herb, one vial of mead and two eggs.",
		},
		question = "Did you gather all necessary ingredients to prepare Filled Jalapeño Peppers with me?",
		cook = {
			"Okay! So after all of these heavy dishes, we're going to create a fast little snack. <starts preparing the peppers as he speaks> ...",
			"First of all, remove the top of the jalapeño peppers and clean their inside, so that you have space for the filling. Now for the filling, we grate the cheese and mix it with the mead and the eggs, until it has a nice consistency. ...",
			"We add the grinded herbs and blend it well. Push a spoonful in each jalapeño pepper until they are nicely stuffed. Now, we shortly fry the jalapeño peppers in a pan to heat them up. ...",
			"The filling will melt nicely, just be careful that it doesn't drip out! And voilà, we're done! ...",
			"This famous dish from Ankrahmun is quite hot and spicy, so only eat one at a time. It's also possible that you get the urge to run really fast afterwards. Enjoy!",
		},
	},
	{
		name = "Blessed Steak",
		words = { "blessed steak", "steak" },
		reward = 9086,
		ingredients = { { 3582, 1 }, { 8011, 5 }, { 8015, 1 }, { 8017, 2 }, { 3594, 1 }, { 8016, 2 } },
		intro = {
			"The next dish we are going to prepare together is called {Blessed Steak}. <giggles> I'm sorry, I couldn't resist the pun with this one. ...",
			"Don't worry, there's no temple trip awaiting you. Just bring me the following: one piece of ham, five plums, one onion, two beetroots, one pumpkin and two jalapeño peppers.",
		},
		question = "Did you gather all necessary ingredients to prepare a Blessed Steak with me?",
		cook = {
			"Here we go! <pounds with his bare hands on the steak> This will break through the meat fibres, making our steak more tender for this fine Daramanian dish. ...",
			"It's easy to prepare, just chop and sweat the onions and add small pieces of pumpkin, beetroot, plums and peppers. Put the steak into the pan too to let it absorb some of the sweet and fruity flavour. ...",
			"Finally, remove the fruits and onions from the pan and fry the steak from both sides until it's crisp and crusty. Put on a plate and decorate with the fruit mix. ...",
			"The people of Darashia say that it has magical abilities and will help you if you feel totally drained. Enjoy!",
		},
	},
	{
		name = "Northern Fishburger",
		words = { "northern fishburger", "fishburger" },
		reward = 9088,
		ingredients = { { 3580, 1 }, { 7158, 1 }, { 7159, 1 }, { 3581, 5 }, { 3601, 2 }, { 3737, 1 } },
		intro = {
			"The next dish we are going to prepare together is called {Northern Fishburger}. I hope you like fish, not everyone does. This one is a specialty I picked up in Svargrond. ...",
			"Bring me the following ingredients and I'll show you how it's done: one northern pike, one rainbow trout, one green perch, five shrimps, two rolls and one fern.",
		},
		question = "Did you gather all necessary ingredients to make a Northern Fishburger with me?",
		cook = {
			"Great! After all this meat, we shouldn't neglect to prepare some fish. <carefully removes heads, tails and bones from the fishes and peels shrimps at incredible speed> ...",
			"This easy dish from Svargrond is what you'd call fast food, but its outstanding taste justifies to put it in my book about 'Hot Cuisine'. ...",
			"Simply cut the rolls in half, shortly fry one slice of each fish type, put in the shrimps and spice up with grinded fern, which, by the way, tastes slightly like dill. ...",
			"Nicely decorate it on a plate, and voilà, we're done already! Can't tell you much about the effects, but fishermen in Svargrond seem to love it. Enjoy!",
		},
	},
	{
		name = "Carrot Cake",
		words = { "carrot cake" },
		reward = 9087,
		ingredients = { { 3595, 5 }, { VIAL, 1, 9 }, { 8013, 1 }, { 3603, 10 }, { 3606, 2 }, { 3598, 10 }, { 841, 2 } },
		intro = {
			"The last dish we are going to prepare together is called {Carrot Cake}. Yes, it's a real cake, we need a tasty desert to complete our cooking course. ...",
			"Bring me the following ingredients and I'll lead you through it: five carrots, one vial of milk, one lemon, ten ounces of flour, two eggs, ten cookies and two peanuts.",
		},
		question = "Did you gather all necessary ingredients to bake a Carrot Cake with me?",
		cook = {
			"So, now for our final dish - a grand dessert from the amazon girls at Carlin! <grates carrots during his explanations> ...",
			"It's easy as it can be - mix a normal cake dough with milk, flour and eggs, then add some cookie crumbs for the crunchy effect later on. ...",
			"Stir in the grated carrots and tiny peanut pieces and bake it for about thirty minutes! Now we'll make a great topping with sugar and lemon juice, pour it over the cake and decorate it. ...",
			"And voilà, we're done! The girls of Carlin swear that it sharpens their eyesight, at least for a while. I'm sure it will somehow aid you in your battles. Enjoy!",
		},
		-- only the first time; the last line is ours (EN: "...I promise that I will cook each dish once with you,
		-- but then I have to take care of my other apprentices", which the yearly limit needed)
		firstTime = {
			"Oh, which reminds me - my little apprentice, we are finished with our cooking course. I think you did great and if it was my decision, you could open your own tavern. ...",
			"But anyway, it's up to you what you make of your newly discovered skills! In case you forget my recipes, please feel free to take a copy of the cookbook upstairs. ...",
			"You can drop by and practice cooking those dishes whenever you like - just bring the ingredients. And if you're hungry for more, ask me about my new {menu}. Cheers to you!",
		},
		firstTimeAnnual = {
			"Oh, which reminds me - my little apprentice, we are finished with our cooking course. I think you did great and if it was my decision, you could open your own tavern. ...",
			"But anyway, it's up to you what you make of your newly discovered skills! In case you forget my recipes, please feel free to take a copy of the cookbook upstairs. ...",
			"You can drop by and practice cooking those dishes, at least during the time that I'm at home. I promise that I will cook each dish once with you, but then I have to take care of my other apprentices. Cheers to you!",
		},
	},
	{
		name = "Coconut Shrimp Bake",
		words = { "coconut shrimp bake", "shrimp bake" },
		reward = 11584,
		ingredients = { { VIAL, 5, 15 }, { 3725, 5 }, { 3724, 5 }, { 10329, 10 }, { 3581, 10 } },
		intro = {
			"Yes, you heard that right! Even though I was laying sick on my divan for weeks, I have some new dishes for you. Ehem. Of course I couldn't have done it without my little helpers travelling around the world and discovering recipes. ...",
			"So... <rubs hands together> ... each good menu needs an amazing starter to awaken and stimulate all the little taste buds on your tongue. We're going to cook a nice portion of {Coconut Shrimp Bake}! ...",
			"This is an exotic rice dish with hints of mushrooms and shrimps, topped with sweet coconut goodness - brought to me by a beautiful druid lady a few days ago. My mouth starts watering already! ...",
			"... because of the dish, I mean, of course. Ehem. Bring me the following ingredients and we'll get started: Five vials of coconut milk, five brown mushrooms, five red mushrooms, ten rice balls and ten shrimps.",
		},
		question = "Did you gather all necessary ingredients to prepare a Coconut Shrimp Bake with me?",
		cook = {
			"Yum! Just the thought of it makes me drool. <tosses the shrimps into a bowl and soaks them in coconut milk as he goes on chopping all mushrooms in the blink of an eye> ...",
			"I see you brought real Zaoan rice balls! That saves us a lot of time as we don't have to cook the rice anymore. Now we just flatten them out nice and medium thick on this baking tray. <squeezes and smoothes the rice piles with his fingers> ...",
			"In the meantime, our shrimps have absorbed some of the coconut milk and we can now add them on top of the rice. <spreads them evenly across the rice and pours the coconut milk from the bowl over the rice> ...",
			"Now we just need to add the mushrooms <tosses them all over the tray>, pour the rest of the coconut milk over it and put it into the oven! ...",
			"... dum di dum ... <waits> ...",
			"Aaaaaaand there you go! Sweet coconut goodness! And psst - the shrimps add some submarine flavour to this dish. You should definitely eat it while walking underwater and wearing a helmet of the deep. Just in case. Enjoy!",
		},
	},
	{
		name = "Blackjack",
		words = { "blackjack" },
		reward = 11586,
		ingredients = { { 10456, 5 }, { VIAL, 2, 1 }, { 3595, 20 }, { 8010, 10 }, { 8016, 3 } },
		intro = {
			"After this wonderful and tasty starter we're all set for a special dish I learnt from a brave adventurer who almost starved when he got lost in the mountains between Ankrahmun and Port Hope, or so he told me. ...",
			"Luckily, he was saved by nomads - can you imagine? - and they fed him a special local dish that's very cheap and easy to prepare, yet rich in vitamins and spending energy for hours. ...",
			"Now don't be shocked, but - they do put sandcrawlers in there. When I tried to prepare that dish at first, I was repelled by its awful appearance, but since it smelled so good I did take a sip and was pleasantly surprised of the great taste. ...",
			"According to the adventurer, this meal works well with any kind of vegetables or any kind of edible creepy-crawlers, depending on what the nomads get their hands on, but we'll stick to the original for now! ...",
			"Bring me the following ingredients - if you dare - and I'll show you the secret of {Blackjack}: Five sandcrawler shells, two vials of water, twenty carrots, ten potatoes and three jalapeño peppers.",
		},
		question = "Did you gather all necessary ingredients to cook a Blackjack with me?",
		cook = {
			"Awesome! Let's go! Let's start with preparing the sandcrawlers <starts boiling water on a stove and tosses the sandcrawler shells in there> ...",
			"I understand your scepticism, but believe me, all will be well! As you can see, they change colour from dark to light red, and that's when they also start turning soft. <stirs with one hand while he slices carrots and peppers with the other hand> ...",
			"Now add whole potatoes and let everything cook at high temperature until the potatoes are so soft they're basically falling apart. <mashes really fast, creating something of a dark brownish colour that doesn't really look tasty> ...",
			"Yes yes, I know, don't give me that look! You'll be surprised! Now just add the chopped carrots and chili for a healthy portion of vitamins and spices, keep stiring and mashing and let it simmer for about an hour. ...",
			"You're wondering why I chose a simple recipe like that for my famous menu? You'll know when you taste it! ...",
			"Heeeeeere you are - just a few spoons of this great stew make you so full that the bowl I give you will last for a long time until it's finally depleted. Enjoy!",
		},
	},
	{
		name = "Demonic Candy Balls",
		words = { "demonic candy balls", "demonic candy ball", "candy balls", "candy ball" },
		reward = 11587,
		rewardCount = 5,
		ingredients = { { 6569, 3 }, { 3599, 3 }, { 6574, 2 }, { 6500, 15 }, { 6558, 1 } },
		intro = {
			"Weren't you surprised by the great taste of our main dish? In case you still have some space left in your tummy, we're in for a sweet and fun dessert - but beware unwanted side effects! ...",
			"It was introduced to me by a fearless knight who invented this recipe rather by accident when a bottle of demonic blood broke in his backpack and spilled its contents over his bag of candy balls. ...",
			"Curiously, he tried one and red steam came out of his ears - but it tasted so great that he instantly popped another one in his mouth, and then another, and another. ...",
			"Each one seemed to cause a different effect and he was never really sure what the next one would do. Seems safer to be careful with them and not to eat them in dangerous situations! ...",
			"In any case, bring me the following ingredients and we'll make some {Demonic Candy Balls}, if you like: Three candies, three candy canes, two bars of chocolate, fifteen gingerbread men and one concentrated demonic blood.",
		},
		question = "Did you gather all necessary ingredients to make Demonic Candy Balls with me?",
		cook = {
			"Very nice! I'm ready for action! <quickly grabs all the candies, candy canes and gingerbread men and crushes them with amazing speed> ...",
			"After having crushed all those sweets, we need to melt the chocolate into a thick liquid... <creates a magical flame by snapping his fingers and melts the chocolate so fast over the sweets that it's amazing he didn't spill it everywhere> ...",
			"... and form little balls together with the sweets! <shapes candy balls about the size of rice balls faster and more perfectly than any mortal ever could> ...",
			"Now, carefully, we add the demonic blood... <and time seems to stand still as seemingly for the first time ever he does something slowly, pouring a single drop of concentrated demonic blood onto each ball> ...",
			"Here you go, but beware possible side effects! You never know for sure what will happen and so far all of those I tried had awesome effects, so of course I don't hope for nasty surprises! Enjoy!",
		},
	},
	{
		name = "Sweet Mangonaise Elixir",
		words = { "sweet mangonaise elixir", "mangonaise" },
		reward = 11588,
		ingredients = { { 3606, 40 }, { 5096, 20 }, { 5902, 10 }, { 8758, 1 }, { 5942, 1 } },
		intro = {
			"Did you dare eat all of your Demonic Candy Balls...? Hehehe! Well, I almost forgot one of the most essential parts for a perfect dinner. A drink! I have one for you, almost a designer drink you could say. ...",
			"Its inventor seems to have done some scientific research in order to achieve his desired effect, which is - charging magical rings. You have to drink it while you're wearing one for a miraculous effect! ...",
			"Bring me the following ingredients and we'll get started: Fourty eggs, twenty mangos, ten honeycombs, one bottle of bug milk and one blessed wooden stake. ...",
			"Oh yes, I understand your worries about the eggs, but just make sure they're fresh and all should be fine for our {Sweet Mangonaise Elixir}!",
		},
		question = "Did you gather all necessary ingredients to mix Sweet Mangonaise Elixir with me?",
		cook = {
			"Time to have a sweet drink! Let's pour the bug milk into my cauldron and heat it over fire until it's boiling... <starts slicing mangoes in the meantime> there! ...",
			"Now we're breaking all of the eggs into there - 1, 2, 10, 20, 40 <ticktickcrack> crumble the honeycombs and toss the sliced mangoes into the hot mix. ...",
			"Now we just have to let it simmer and stir using a blessed wooden stake <stirs so vigorously that you can barely see his arms anymore> for thirty minutes. ...",
			"By now, the power of the blessed wooden stake will have been transferred into our elixir, so let's put out the fire and let it cool down. ...",
			"<carefully pours the cooled elixir into a small bottle or glass> There! Its inventor said it had amazing effects on the ring you're wearing, as long as the ring is based on time, not on charges. Enjoy!",
		},
		firstTime = {
			"And by the way... since those were all the recipes from this year and you cooked them so nicely, you may take the cookbook containing them from upstairs, if you like!",
		},
	},
	{
		-- BR lines only (EN has no transcript of it); typos of the BR text fixed ("area", "pallatel")
		name = "Zaoan Sauce",
		words = { "zaoan sauce" },
		reward = 50334,
		ingredients = { { 33930, 1 }, { VIAL, 2, 15 }, { 11682, 1 }, { 31590, 1 }, { 48115, 1 } },
		intro = {
			"What a drink! Did I promise too much? I guess not, judging by your satisfied look! Well, if you are really that eager - there's more. ...",
			"Another part of a meal or even a course of several meals that should not be underestimated is the sauce. ...",
			"How about a delicious sweet and sour {Zaoan Sauce} to accompany your meal, exciting, fresh and pleasing to the palate. ...",
			"We need the following ingredients to get cracking: a pinch of salt, two vials of coconut milk, a dragon fruit, a young lich worm and a taiyaki. ...",
			"What? You think that lich worm will not go well with the dragon fruit? Worry not, for this is a vital ingredient to the 'sour' part of this excellent sweet and sour sauce!",
		},
		question = "Did you gather all necessary ingredients to cook the Zaoan Sauce with me?",
		cook = {
			"And we are off to start with our sauce! First pour the coconut milk into my cauldron and, yes you may have already expected that, heat it over fire until it's boiling. <salts the young lich worms in the meantime> ...",
			"Now we're cutting the dragon fruit and toss the sliced goodness into the mix <flubbflubb>. ...",
			"Now we calmly slice and add the taiyaki to get that certain sweet impression. <drops the slices into the cauldron> There! ...",
			"How did this ancient saying about this sweet yet sour sauce go, something along the lines of inner harmony and balance of body and soul - well, I can't remember the exact wording right now. ...",
			"What I do know is that you will absolutely benefit from tasting the soup. Bon appétit!",
		},
	},
}
H.courseEnd = 10 -- dishes 1-10 are the course ("recipe"), 11-15 the menu ("menu")
H.lastDish = #H.dishes

local function storages()
	return Storage.Quest.U8_5.HotCuisineQuest
end

-- Next dish to learn (1-15), 16 when all are learned; upstream values kept (15 after the elixir).
function H.nextDish(player)
	local n = player:getStorageValue(storages().CurrentDish)
	if n < 1 then
		return 1
	end
	return math.min(n, H.lastDish + 1)
end

function H.started(player)
	return player:getStorageValue(storages().QuestStart) >= 1
end

function H.dishByWord(message)
	-- longest phrases first, so "demonic candy balls" wins over "candy ball"
	local best, bestLen
	for index, dish in ipairs(H.dishes) do
		for _, word in ipairs(dish.words) do
			if MsgContains(message, word) and (not bestLen or #word > bestLen) then
				best, bestLen = index, #word
			end
		end
	end
	return best
end

local function ingredientName(ingredient)
	local id, count, fluid = ingredient[1], ingredient[2], ingredient[3]
	if fluid then
		return string.format("%d %s of %s", count, count == 1 and "vial" or "vials", FLUID_NAMES[fluid] or "fluid")
	end
	local it = ItemType(id)
	if count == 1 then
		return "1 " .. it:getName()
	end
	local plural = it:getPluralName()
	if not plural or plural == "" then
		plural = it:getName()
	end
	return count .. " " .. plural
end

function H.missing(player, index)
	local missing = {}
	for _, ingredient in ipairs(H.dishes[index].ingredients) do
		local have = player:getItemCount(ingredient[1], ingredient[3] or -1)
		if have < ingredient[2] then
			missing[#missing + 1] = ingredientName({ ingredient[1], ingredient[2] - have, ingredient[3] })
		end
	end
	return missing
end

function H.takeIngredients(player, index)
	if #H.missing(player, index) > 0 then
		return false
	end
	for _, ingredient in ipairs(H.dishes[index].ingredients) do
		player:removeItem(ingredient[1], ingredient[2], ingredient[3] or -1)
	end
	return true
end

-- Culinary Master: how often each dish was cooked (dishes learned before 2026-11-16 count once).
function H.cookedCount(player, index)
	local value = player:kv():scoped(H.kvScope):get("cooked-" .. index)
	if value then
		return tonumber(value) or 0
	end
	return index < H.nextDish(player) and 1 or 0
end

local function checkAchievement(player)
	if player:hasAchievement(H.achievement) then
		return
	end
	for index = 1, H.achievementDishes do
		if H.cookedCount(player, index) < 2 then
			return
		end
	end
	player:addAchievement(H.achievement)
end

-- Family.hotCuisineAnytime = false: once per calendar year and dish, as in Tibia.
local function cookedThisYear(player, index)
	local year = player:kv():scoped(H.kvScope):get("year-" .. index)
	return year ~= nil and tonumber(year) == tonumber(os.date("%Y"))
end

function H.isOpen()
	return Family.hotCuisineAnytime or tonumber(os.date("%m")) == 8
end

local function setProgress(player, index)
	local S = storages()
	player:setStorageValue(S.CurrentDish, index + 1)
	-- quest log: 2-11 after dishes 1-10, 12 = menu heard, 13-16 after dishes 11-14, 17 after Zaoan Sauce
	player:setStorageValue(S.QuestLog, index <= H.courseEnd and index + 1 or index + 2)
	if index == H.courseEnd then
		player:setStorageValue(S.CookbookDoor, 1)
	elseif index == 14 then
		player:setStorageValue(S.QuestStart, 2)
		player:setStorageValue(S.CookbookDoor2, 1)
	end
end

-- Cooks dish `index` (ingredients already checked). Returns the lines he says.
function H.cookDish(player, index)
	local dish = H.dishes[index]
	local first = index == H.nextDish(player)
	local cooked = H.cookedCount(player, index) -- before the course moves on
	local lines = {}
	for _, line in ipairs(dish.cook) do
		lines[#lines + 1] = line
	end
	if first then
		local extra = (not Family.hotCuisineAnytime and dish.firstTimeAnnual) or dish.firstTime
		for _, line in ipairs(extra or {}) do
			lines[#lines + 1] = line
		end
		-- the line before the extra lines must end with "..." (one more message follows)
		if extra and #extra > 0 then
			local k = #dish.cook
			if not lines[k]:find("%.%.%.$") then
				lines[k] = lines[k] .. " ..."
			end
		end
		setProgress(player, index)
	end
	player:addItem(dish.reward, dish.rewardCount or 1)
	local kv = player:kv():scoped(H.kvScope)
	kv:set("cooked-" .. index, cooked + 1)
	kv:set("year-" .. index, tonumber(os.date("%Y")))
	checkAchievement(player)
	return lines
end

-- Talk ------------------------------------------------------------------------------------------

local TOPIC_COOK, TOPIC_RECIPES, TOPIC_APPRENTICE, TOPIC_DISH = 1, 2, 3, 100

local function dishList()
	local names = {}
	for _, dish in ipairs(H.dishes) do
		names[#names + 1] = "{" .. (dish.listName or dish.name) .. "}"
	end
	return table.concat(names, ", ")
end

local function learnedList(player)
	local names = {}
	for index = 1, H.nextDish(player) - 1 do
		local dish = H.dishes[index]
		names[#names + 1] = "{" .. (dish.listName or dish.name) .. "}"
	end
	return table.concat(names, ", ")
end

function H.greet(npcHandler, npc, player)
	local S = storages()
	-- older characters who finished the elixir before Cookbook II got its own door
	if player:getStorageValue(S.QuestStart) >= 2 and player:getStorageValue(S.CookbookDoor2) < 1 then
		player:setStorageValue(S.CookbookDoor2, 1)
	end
	if not H.started(player) then
		npcHandler:setMessage(MESSAGE_GREET, "Greetings, |PLAYERNAME|. What are you doing out here?")
	elseif H.nextDish(player) <= H.courseEnd then
		npcHandler:setMessage(MESSAGE_GREET, "Hello there again, |PLAYERNAME|! I guess you're back for some cooking - let's get going then!")
	else
		-- BR (the greeting of the menu year)
		npcHandler:setMessage(MESSAGE_GREET, "Hello there again, |PLAYERNAME|! I've finally recovered from this bad - achoo - cold, well almost! But it feels great to be able to smell and taste again. If you're here for some cooking, let's get started!")
	end
end

local function sayIntro(npcHandler, npc, creature, player, index)
	npcHandler:say(H.dishes[index].intro, npc, creature)
	local S = storages()
	if index == H.courseEnd + 1 and player:getStorageValue(S.QuestLog) < 12 then
		player:setStorageValue(S.QuestLog, 12)
	end
end

local function askDish(npcHandler, npc, creature, player, index)
	local playerId = player:getId()
	local nextDish = H.nextDish(player)
	if index > nextDish then
		-- ours
		local word = nextDish <= H.courseEnd and "{recipe}" or "{menu}"
		npcHandler:say(string.format("Patience, my little apprentice! I haven't taught you that dish yet. Ask me for a %s and we'll cook the dishes in their proper order.", word), npc, creature)
		npcHandler:setTopic(playerId, 0)
		return
	end
	if not Family.hotCuisineAnytime and index < nextDish and cookedThisYear(player, index) then
		-- ours (upstream: "It seems you have already cooked this dish this year. Please come back next year in August.")
		npcHandler:say("We have already cooked this dish together this year. Please come back next year in August.", npc, creature)
		npcHandler:setTopic(playerId, 0)
		return
	end
	npcHandler:say(H.dishes[index].question, npc, creature)
	npcHandler:setTopic(playerId, TOPIC_DISH + index)
end

function H.onSay(npcHandler, npc, creature, message)
	local player = Player(creature)
	local playerId = player:getId()
	local topic = npcHandler:getTopic(playerId)
	local S = storages()

	if not H.started(player) then
		if MsgContains(message, "cook") then
			npcHandler:say("Well, I'm not a simple cook. I travel the whole Tibian continent for the most artfully seasoned {recipes} and constantly develop new ones.", npc, creature)
			npcHandler:setTopic(playerId, TOPIC_COOK)
		elseif MsgContains(message, "recipes") or MsgContains(message, "recipe") or MsgContains(message, "menu") then
			npcHandler:say("You're interested in my recipes? Well. They are not for sale, but if you want to become my {apprentice}, I'll share my knowledge with you.", npc, creature)
			npcHandler:setTopic(playerId, TOPIC_RECIPES)
		elseif MsgContains(message, "apprentice") then
			if player:getLevel() < H.level then
				npcHandler:say("Hmm. You look quite promising. However, I fear you're still a little young. Come back when you've grown a bit and I'll gladly take you as my apprentice.", npc, creature)
				npcHandler:setTopic(playerId, 0)
			else
				npcHandler:say("Hmm. You look quite promising. Can't hurt to give it a try, I guess. Would you like to become my apprentice, |PLAYERNAME|?", npc, creature)
				npcHandler:setTopic(playerId, TOPIC_APPRENTICE)
			end
		elseif topic == TOPIC_APPRENTICE and MsgContains(message, "yes") then
			npcHandler:say("Fine, young human. Ask me for a {recipe} anytime and I'll teach you what I know.", npc, creature)
			player:setStorageValue(S.QuestStart, 1)
			player:setStorageValue(S.CurrentDish, 1)
			player:setStorageValue(S.QuestLog, 1)
			npcHandler:setTopic(playerId, 0)
		elseif topic == TOPIC_APPRENTICE and MsgContains(message, "no") then
			-- ours
			npcHandler:say("No? Well, my kitchen stays open for you, in case you change your mind.", npc, creature)
			npcHandler:setTopic(playerId, 0)
		elseif H.dishByWord(message) then
			-- ours
			npcHandler:say("I only cook my dishes together with my apprentices. Would you like to become my {apprentice}?", npc, creature)
			npcHandler:setTopic(playerId, 0)
		end
		return true
	end

	local nextDish = H.nextDish(player)

	if topic > TOPIC_DISH then
		local index = topic - TOPIC_DISH
		if MsgContains(message, "yes") then
			npcHandler:setTopic(playerId, 0)
			local missing = H.missing(player, index)
			if #missing > 0 then
				-- upstream line, with the list (ours)
				npcHandler:say("Make sure that you have all the ingredients with you. I'm still missing " .. table.concat(missing, ", ") .. ".", npc, creature)
				return true
			end
			H.takeIngredients(player, index)
			npcHandler:say(H.cookDish(player, index), npc, creature)
			return true
		elseif MsgContains(message, "no") then
			npcHandler:say("No?, come back when you are ready to cook.", npc, creature)
			npcHandler:setTopic(playerId, 0)
			return true
		end
	end

	local index = H.dishByWord(message)
	if index then
		askDish(npcHandler, npc, creature, player, index)
	elseif MsgContains(message, "recipes") or MsgContains(message, "recipe") or MsgContains(message, "cook") then
		if nextDish <= H.courseEnd then
			sayIntro(npcHandler, npc, creature, player, nextDish)
		elseif nextDish <= H.lastDish then
			-- BR, without the yearly limit (ours: "whenever you like" for "unless you haven't done so already this year")
			npcHandler:say({
				"I have a special treat for you! Thanks to gourmets all over the world sending me inspiring ideas, I was able to prepare a {menu} which we can cook together. ...",
				"We can also recook my own recipes whenever you like. Just ask me for a dish you'd like to cook and bring the ingredients you can find in the cookbook I gave you last time.",
			}, npc, creature)
		else
			-- ours
			npcHandler:say("You know all my recipes now, my little apprentice! We can cook any of them whenever you like, just bring the ingredients: " .. dishList() .. ".", npc, creature)
		end
		npcHandler:setTopic(playerId, 0)
	elseif MsgContains(message, "menu") then
		if nextDish <= H.courseEnd then
			-- ours
			npcHandler:say("One thing after another! First we finish my cooking course. Ask me for a {recipe}.", npc, creature)
		elseif nextDish <= H.lastDish then
			sayIntro(npcHandler, npc, creature, player, nextDish)
		else
			-- ours
			npcHandler:say("We have cooked my whole menu together! Ask me for any dish you'd like to cook again: " .. learnedList(player) .. ".", npc, creature)
		end
		npcHandler:setTopic(playerId, 0)
	elseif MsgContains(message, "apprentice") then
		-- ours
		npcHandler:say("You are already my apprentice, |PLAYERNAME|! Ask me for a {recipe} and let's cook.", npc, creature)
	end
	return true
end
