Class PKCardsMenu : PKCGenericMenu {
	const BOARD_WIDTH = 1024;
	const BOARD_HEIGHT = 768;
	double backgroundRatio;
	vector2 boardTopLeft;
	
	PlayerPawn plr;
	
	PK_BoardEventHandler menuEHandler;
	PK_BoardElementsHandler elementsEHandler;
	
	PK_CardControl goldcontrol;
	
	PKCMenuHandler handler;
	PKCCardButton SelectedCard;	//card attached to the pointer
	PKCCardButton HoveredCard;	//card the pointer is hovering over
	
	PKCFrame boardElements;		//everything in the board except the background and popups
	PKCBoardMessage cardinfo;		//card information popup
	PKCBoardMessage exitPopup;	//exit prompt popup
	PKCBoardMessage firstUsePopup;	//first use notification
	int firstUsePopupDur;				//first use notification display duration
	
	PKCButton exitbutton;			//big round flashing menu close button
	bool ExitHovered;				//whether it's hovered
	int ExitAlphaDir;
	
	bool firstUse;
	
	override void Init (Menu parent) {
		super.Init(parent);
		
		/*vector2 screensize = (Screen.GetWidth(),screen.GetHeight());		
		SetBaseResolution(screensize);
		backgroundRatio = screensize.y / BOARD_HEIGHT;
		vector2 backgroundsize = (BOARD_WIDTH*backgroundRatio,BOARD_HEIGHT*backgroundRatio);
		boardTopLeft = */
		
		//checks if the board is opened for the first time on the current map:
		menuEHandler = PK_BoardEventHandler(EventHandler.Find("PK_BoardEventHandler"));
		if (menuEHandler) {
			if (!menuEHandler.boardOpened) {
				firstUse = true;
				menuEHandler.boardOpened = true;
			}
			else
				firstUse = false;
		}
		
		elementsEHandler = PK_BoardElementsHandler(EventHandler.Find("PK_BoardElementsHandler"));
		
		let plr = players[consoleplayer].mo;
		goldControl = PK_CardControl(plr.FindInventory("PK_CardControl"));
		
		//first create the background (always 4:3, never stretched)
		vector2 backgroundsize = (BOARD_WIDTH,BOARD_HEIGHT);	
		SetBaseResolution(backgroundsize);
		let background = new("PKCImage");
		background.Init(
			(0,0),
			backgroundsize,
			image:"graphics/Tarot/cardsboard.png"/*,
			imagescale:(1*backgroundRatio,1*backgroundRatio)*/
		);
		background.Pack(mainFrame);
		
		//define the frame that will keep everything except text popups:
		boardelements = new("PKCFrame").Init((0,0),backgroundsize);
		boardelements.pack(mainFrame);

		handler = new("PKCMenuHandler");
		handler.menu = self;
		
		//create big round exit button:
		exitbutton = new("PKCButton").Init(
			(511,196),
			(173,132),
			cmdhandler:handler,
			command:"BoardButton"
		);
		exitbutton.SetTexture(
			"Graphics/Tarot/board_button_highlighted.png",
			"Graphics/Tarot/board_button_highlighted.png",
			"Graphics/Tarot/board_button_highlighted.png",
			"Graphics/Tarot/board_button_highlighted.png"
		);
		exitbutton.Pack(boardelements);
		
		SlotsInit();	//initialize card slots
		CardsInit();	//initialize cards
		
		//unlock 2 random silver and 3 random gold crads if you have none unlocked ("pistol start"):		
		if (goldcontrol && goldControl.UnlockedTarotCards.Size() == 0) {
			//S_StartSound("ui/board/cardunlocked",CHAN_AUTO,CHANF_UI);
			S_StartSound("ui/board/cardburn",CHAN_AUTO,CHANF_UI);
			
			//show "first use" text popup (doesn't block the board):
			firstUsePopup = New("PKCBoardMessage");
			firstUsePopup.pack(mainFrame);
			firstUsePopup.Init(
				(192,256),
				(700,128),
				"$TAROT_FIRSTUSE",
				textscale: 1.5
			);
			firstUsePopupDur = 120;	//"first use" message is temporary
			
			//these arrays are used to make sure we don't unlock the same card more than once:
			array <PKCCardButton> UnlockedGoldCards;
			array <PKCCardButton> UnlockedSilverCards;
			
			//unlock the cards and push them into an array on the item token via a netevent:
			while (UnlockedSilverCards.Size() < 2) {
				let card = silvercards[random(0,silvercards.Size()-4)];
				if (UnlockedSilverCards.Find(card) == UnlockedSilverCards.Size()) {
					card.cardbought = true;
					UnlockedSilverCards.push(card);					
					string eventname = String.Format("PKCUnlockCard:%s",card.cardID);
					EventHandler.SendNetworkEvent(eventname);
				}
			}
			while (UnlockedGoldCards.Size() < 3) {
				let card = goldcards[random(0,goldcards.Size()-4)];
				if (UnlockedGoldCards.Find(card) == UnlockedGoldCards.Size()) {
					card.cardbought = true;
					UnlockedGoldCards.push(card);
					string eventname = String.Format("PKCUnlockCard:%s",card.cardID);
					EventHandler.SendNetworkEvent(eventname);
				}
			}
		}
	}
	
	array <PKCCardButton> silvercards;	//all silver cards
	array <PKCCardButton> goldcards;		//all gold cards
	
	static const int PKCSlotXPos[] = { 58, 231, 489, 660, 829 };
	static const name PKCSlotIDs[] = {
		'slotSilver1',
		'slotSilver2',
		'slotGold1',
		'slotGold2',
		'slotGold3'
	};
	
	private void SlotsInit() {
		vector2 slotsize = (138,227);	
		for (int i = 0; i < 5; i++) {			
			double slotY = (i < 2) ? 179 : 364;
			vector2 slotpos = (PKCSlotXPos[i],slotY);
			let cardslot = PKCCardSlot(new("PKCCardSlot"));
			cardslot.Init(
				slotpos,
				slotsize,
				cmdhandler:handler,
				command:"CardSlot"
			);
			cardslot.SetTexture(
				"","","",""
			);
			cardslot.slotpos = slotpos;
			cardslot.slotsize = slotsize;
			cardslot.slottype = (i < 2) ? false : true;
			cardslot.slotID = PKCSlotIDs[i];
			cardslot.Pack(boardelements);
		}
	}
	//LANGUAGE references containing card names:
	static const string PKCCardNames[] = {
		//silver
		"$SOULKEEPER_NAME"	,	"$BLESSING_NAME"		,	"$REPLENISH_NAME"		,
		"$DARKSOUL_NAME"		,	"$SOULCATCHER_NAME"	,	"$FORGIVENESS_NAME"	,
		"$GREED_NAME"			,	"$SOULREDEEMER_NAME"	,	"$REGENERATION_NAME"	,
		"$HEALTHSTEALER_NAME"	,	"$HELLISHARMOR_NAME"	,	"$666AMMO_NAME"		,
		//gold
		"$ENDURANCE_NAME"		,	"$TIMEBONUS_NAME"		,	"$SPEED_NAME"			,
		"$REBIRTH_NAME"		,	"$CONFUSION_NAME"		,	"$DEXTERITY_NAME"		,
		"$WMODIFIER_NAME"		,	"$SOT_NAME"			,	"$RAGE_NAME"			,
		"$MAGICGUN_NAME"		,	"$IRONWILL_NAME"		,	"$HASTE_NAME"
	};
	//LANGUAGE references containing card descriptions:
	static const string PKCCardDescs[] = {
		//silver
		"$SOULKEEPER_DESC"	,	"$BLESSING_DESC"		,	"$REPLENISH_DESC"		,
		"$DARKSOUL_DESC"		,	"$SOULCATCHER_DESC"	,	"$FORGIVENESS_DESC"	,
		"$GREED_DESC"			,	"$SOULREDEEMER_DESC"	,	"$REGENERATION_DESC"	,
		"$HEALTHSTEALER_DESC"	,	"$HELLISHARMOR_DESC"	,	"$666AMMO_DESC"		,
		//gold
		"$ENDURANCE_DESC"		,	"$TIMEBONUS_DESC"		,	"$SPEED_DESC"			,
		"$REBIRTH_DESC"		,	"$CONFUSION_DESC"		,	"$DEXTERITY_DESC"		,
		"$WMODIFIER_DESC"		,	"$SOT_DESC"			,	"$RAGE_DESC"			,
		"$MAGICGUN_DESC"		,	"$IRONWILL_DESC"		,	"$HASTE_DESC"
	};
	//this is a generic ID also used to find the texture name:
	static const name PKCCardIDs[] = {
		//silver
		"SoulKeeper"			,	"Blessing"				,	"Replenish"			,
		"DarkSoul"				,	"SoulCatcher"			,	"Forgiveness"			,
		"Greed"				,	"SoulRedeemer"			,	"HealthRegeneration"	,
		"HealthStealer"		,	"HellishArmor"			,	"666Ammo"				,
		//gold
		"Endurance"			,	"TimeBonus"			,	"Speed"				,
		"Rebirth"				,	"Confusion"			,	"Dexterity"			,
		"WeaponModifier"		,	"StepsOfThunder"		,	"Rage"					,
		"MagicGun"				,	"IronWill"				,	"Haste"
	};
	
	//I have to define slots' X pos manually because the gaps between them are not precisely identical:
	static const int PKCCardXPos[] = { 56, 135, 214, 291, 370, 447, 525, 604, 682, 759, 835, 913 };
	
	//Initialize cards:
	private void CardsInit() {				
		vector2 cardsize = (55,92);
		vector2 cardscale = (0.4,0.407); //slightly stretched vertically to fill the slot
		for (int i = 0; i < PKCCardIDs.Size(); i++) {
			//first 12 cards are silver, so we define pos based on where we are in the IDs array:
			vector2 cardpos = (i < 12) ? (PKCCardXPos[i],56) : (PKCCardXPos[i-12],618);
			let card = PKCCardButton(new("PKCCardButton"));
			card.Init(
				cardpos,
				cardsize,
				cmdhandler:handler,
				command:"HandleCard"
			);
			string texpath = String.Format("graphics/Tarot/cards/%s.png",PKCCardIDs[i]);
			card.SetTexture(texpath, texpath, texpath, texpath);
			card.buttonScale = cardscale;
			card.defaultscale = cardscale;
			card.defaultpos = cardpos;
			card.defaultsize = cardsize;
			card.cardname = PKCCardNames[i];
			card.carddesc = PKCCardDescs[i];
			card.cardID = PKCCardIDs[i];	
			if (i < 12) {
				card.slottype = false;
				silvercards.push(card);
			}
			else {
				card.slottype = true;
				goldcards.push(card);
			}
			card.Pack(boardelements);
			//check if the card is already unlocked:
			if (goldcontrol && goldControl.UnlockedTarotCards.Find(int(name(card.cardID))) != goldControl.UnlockedTarotCards.Size())
				card.cardbought = true;
		}
	}

	//shows exit popup message
	void ShowExitPopup() {
		if (!boardElements)
			return;
				
		S_StartSound("ui/menu/accept",CHAN_AUTO,CHANF_UI);
		vector2 popuppos = (192,160);
		vector2 popupsize = (640,260);
		
		exitPopup = New("PKCBoardMessage");
		exitPopup.pack(mainFrame);
		exitPopup.Init(
			popuppos,
			popupsize,
			"$TAROT_EXIT",
			textscale: 0.9
		);
		
		let exitHander = PKCExitHandler(new("PKCExitHandler"));
		exitHander.menu = self;		
		
		//create Yes button:
		vector2 buttonsize = (100,60);
		let yesButton = new("PKCButton").Init(
			(100,160),
			buttonsize,
			text:"Yes",
			cmdhandler:exitHander,
			command:"DoExit",
			fnt:font_times,
			textscale:1.5,
			textColor:Font.FindFontColor('PKBaseText')
		);
		yesButton.SetTexture("","","","");
		yesButton.pack(exitPopup);
		
		//create No button:
		let noButton = new("PKCButton").Init(
			(440,160),
			buttonsize,
			text:"No",
			cmdhandler:exitHander,
			command:"CancelExit",
			fnt:font_times,
			textscale:1.5,
			textColor:Font.FindFontColor('PKBaseText')
		);
		noButton.SetTexture("","","","");
		noButton.pack(exitPopup);
	}
	
	void ShowCardToolTip(PKCCardButton card) {				
		vector2 tippos = (62,430);
		vector2 tipsize = (378,173);

		string title = Stringtable.Localize(card.cardname);	//pulls name from LANGUAGE
		string desc = Stringtable.Localize(card.carddesc);	//pulls desc from LANGUAGE
		
		cardinfo = New("PKCBoardMessage");
		cardinfo.pack(mainFrame);
		cardinfo.Init(
			tippos,
			tipsize,
			String.Format("%s",title),
			textscale:1.2,
			textcolor: Font.FindFontColor('PKRedText')
		);
		
		vector2 tiptextofs = (16,16);	
		let tiptext = new("PKCLabel").Init(
			tiptextofs+(0,48),
			tipsize-(tiptextofs*1.2),
			String.Format("%s",desc), 
			font_times,
			textscale:1,
			textcolor: Font.FindFontColor('PKBaseText'),
			linespacing: 0.1
		);
		tiptext.Pack(cardinfo);	
	}

    override bool MenuEvent (int mkey, bool fromcontroller) {
        if (mkey == MKEY_Back && firstUse) {
			if (exitPopup) {
					S_StartSound("ui/menu/back",CHAN_AUTO,CHANF_UI);
					exitPopup.unpack();
					exitPopup.destroy();
				}
				else {
					ShowExitPopup();
				}
				return false;
			}
		return Super.MenuEvent (mkey, fromcontroller);
    }
	
	override void Ticker() {
		if (exitPopup) {
			boardElements.disabled = true;
			return;
		}
		else {
			boardElements.disabled = false;
		}
		
		if (firstUsePopup) {
			firstUsePopupDur--;			
			if (firstUsePopupDur <= 0) {
				firstUsePopup.Unpack();
				firstUsePopup.Destroy();
			}
		}
		
		if (SelectedCard) {			
			SelectedCard.box.pos = boardelements.screenToRel((mouseX,mouseY)) - SelectedCard.box.size / 2;
		}
		if (!cardinfo && HoveredCard && !HoveredCard.disabled && !HoveredCard.hidden && !SelectedCard)
			ShowCardToolTip(HoveredCard);
		if (cardinfo && (!HoveredCard || HoveredCard.disabled || HoveredCard.hidden || SelectedCard)) {
			cardinfo.unpack();
			cardinfo.destroy();
		}
		if (exitbutton) {
			if (exitbutton.alpha <= 0.25)
				ExitAlphaDir = 1;
			else if (exitbutton.alpha >= 1)
				ExitAlphaDir = -1;
			exitbutton.alpha = (exitbutton.isHovered && !SelectedCard) ? 1.0 : Clamp(exitbutton.alpha+0.05*ExitAlphaDir,0.25,1.0);
		}
		super.Ticker();
	}
}

Class PKCBoardMessage : PKCFrame {
	private int dur;
	PKCBoardMessage init (vector2 msgpos, vector2 msgsize, string msgtext = "", double TextScale = 1.0, int TextColor = 0) {
		self.setBox(msgpos, msgsize);
		self.alpha = 1;
	
		let outline = new("PKCImage");
		outline.Pack(self);
		outline.Init(
			(0,0),
			msgsize,
			"graphics/Tarot/tooltip_bg_outline.png",
			imagescale:(1.6,1.6),
			tiled:true
		);
				
		vector2 intofs = (4,4);
		let bkg = new("PKCImage");
		bkg.Pack(self);
		bkg.Init(
			intofs,
			msgsize-(intofs*2),
			"graphics/Tarot/tooltip_bg.png",
			imagescale:(1.6,1.6),
			tiled:true
		);
		
		if (msgtext == "")
			return self;
		
		if (textColor == 0)
			textcolor = Font.FindFontColor('PKWhiteText');
		
		vector2 msgTextOfs = intofs+(12,12);
		let msgPrompt = new("PKCLabel");
		msgPrompt.Pack(self);
		msgPrompt.Init(
			msgTextOfs,
			msgsize-(msgTextOfs*2),
			msgtext,
			font_times,
			textscale:TextScale,
			textcolor: TextColor
		);
		
		return self;
	}
}
		

Class PKCCardSlot : PKCButton {
	vector2 slotpos;
	vector2 slotsize;
	PKCButton placedcard;
	bool slottype;
	name slotID;
}

//same as original Button but also takes an buttonScale argument
Class PKCCardButton : PKCButton {
	bool cardbought;	
	vector2 buttonScale;
	vector2 defaultpos;
	vector2 defaultsize;
	vector2 defaultscale;
	bool slottype;
	string cardname;
	string carddesc;
	name cardID;
	int purchaseFrame;
	override void drawer() {
		string texture = btnTextures[curButtonState];
		TextureID tex = TexMan.checkForTexture(texture, TexMan.Type_Any);
		Vector2 imageSize = TexMan.getScaledSize(tex);			
		imageSize.x *= buttonScale.x;
		imageSize.y *= buttonScale.y;
		drawImage((0,0), texture, true, buttonScale);
		
		if (!cardbought)
			drawTiledImage((0, 0), box.size, "graphics/Tarot/tooltip_bg.png", true, buttonScale,alpha: 0.75);

		else if (purchaseFrame <= 16) {
			purchaseFrame++;
			string tex = String.Format("graphics/Tarot/cardburn/pkcburn%d.png",purchaseFrame);
			drawImage((0,0),tex,true,buttonScale);
		}		
	}
}

Class PKCExitHandler : PKCHandler {
	PKCardsMenu menu;
	
	override void buttonClickCommand(PKCButton caller, string command) {
		if (!menu)
			return;
		if (command == "DoExit") {
			S_StartSound("ui/board/exit",CHAN_AUTO,CHANF_UI);
			menu.Close();
		}
		else if (command == "CancelExit") {
			S_StartSound("ui/menu/back",CHAN_AUTO,CHANF_UI);
			let popup = menu.exitPopup;
			if (popup) {
				Popup.Unpack();
				Popup.destroy();
			}
		}
	}
	override void elementHoverChanged(PKCElement caller, string command, bool unhovered) {
		if (!menu)
			return;
		if (command == "DoExit" || command == "CancelExit") {
			let btn = PKCButton(caller);			
			if (!unhovered) {
				btn.textscale = 1.8;
				btn.textcolor = Font.FindFontColor('PKRedText');
				S_StartSound("ui/menu/hover",CHAN_AUTO,CHANF_UI);
			}
			else {
				btn.textscale = 1.5;
				btn.textcolor = Font.FindFontColor('PKBaseText');
			}
		}
	}
}

Class PKCMenuHandler : PKCHandler {
	PKCardsMenu menu;
	PKCCardSlot hoveredslot;
	
	override void buttonClickCommand(PKCButton caller, string command) {
		if (!menu)
			return;
		//exit button - works if you don't have a picked card:
		if (command == "BoardButton" && !menu.SelectedCard) {
			if (menu.firstUse)
				menu.ShowExitPopup();	
			else
				menu.Close();
			return;
		}
		if (menu.exitPopup)
			return;
		if (menu.firstUsePopup) {
			menu.firstUsePopup.Unpack();
			menu.firstUsePopup.Destroy();
		}
		//card slot: if you have a card picked and click the slot, the card will be placed in it and scaled up to its size:
		if (command == "CardSlot") {			
			let cardslot = PKCCardSlot(Caller);
			//check if there's a selected card
			if (menu.SelectedCard) {
				//if the card's type matches the slot's, place it in the slot:
				let card = PKCCardButton(menu.SelectedCard);	
				if (card.slottype == cardslot.slottype) {
					menu.SelectedCard = null; //detach from cursor
					card.box.pos = cardslot.slotpos;
					card.box.size = cardslot.slotsize;
					card.buttonscale = (1,1);
					//if there was a card place in the slot, move that card back to its default pos first, then place this one
					if (cardslot.placedcard) {
						let placedcard = PKCCardButton(cardslot.placedcard);
						placedcard.box.size = placedcard.defaultsize;
						placedcard.box.pos = placedcard.defaultpos;
						placedcard.buttonscale = placedcard.defaultscale;
					}
					cardslot.placedcard = card;
					sound snd = (cardslot.slottype) ? "ui/board/placegold" : "ui/board/placesilver";
					S_StartSound(snd,CHAN_AUTO,CHANF_UI);
				}
				else				
					S_StartSound("ui/board/wrongplace",CHAN_AUTO,CHANF_UI);
			}
			//otherwise check if there's a card in the slot; if there is, pick it up and attach to mouse pointer
			else if (cardslot.placedcard) {
				let card = PKCCardButton(cardslot.placedcard);
				card.box.size = card.defaultsize;
				card.buttonscale = card.defaultscale;
				S_StartSound("ui/board/takecard",CHAN_AUTO,CHANF_UI);
				cardslot.placedcard = null;
				menu.SelectedCard = card;
				//move it to the top of the elements array so that it's rendered on the top layer:
				menu.boardelements.elements.delete(menu.boardelements.elements.find(card));
				menu.boardelements.elements.push(card);
			}
		}
		//clicking the card: attaches card to mouse pointer, or, if you already have one and you click *anywhere* where there's no card slot, the card will jump back to its original slot:
		if (command == "HandleCard") {
			let card = PKCCardButton(Caller);
			if (!card.cardbought) {
				S_StartSound("ui/board/wrongplace",CHAN_AUTO,CHANF_UI);
				return;
			}
			//don't do anything if you're hovering over a valid slot: we don't want placing into slot and clicking the card to happen at the same time
			if (hoveredslot) {
				//if clicking over incorrect slot color, don't jump back but instead play "wrong slot" sound
				if(hoveredslot.slottype != card.slottype)
					S_StartSound("ui/board/wrongplace",CHAN_AUTO,CHANF_UI);
				return;
			}
			//if not hovering over slot, take card and attach it to the menu
			if (!menu.SelectedCard) {
				S_StartSound("ui/board/takecard",CHAN_AUTO,CHANF_UI);
				menu.SelectedCard = card;
				//move it to the top of the elements array so that it's rendered on the top layer:
				menu.boardelements.elements.delete(menu.boardelements.elements.find(card));
				menu.boardelements.elements.push(card);
			}
			//if we already have a card, put it back
			else {
				S_StartSound("ui/board/returncard",CHAN_AUTO,CHANF_UI);
				card.box.pos = card.defaultpos;
				menu.SelectedCard = null;
			}
		}
	}
	
	override void elementHoverChanged(PKCElement caller, string command, bool unhovered) {
		if (!menu)
			return;
		if (menu.exitPopup)
			return;
		//play sound of hovering over the exit button:
		if (command == "BoardButton" && !menu.SelectedCard) {
			if (!unhovered) {
				S_StartSound("ui/board/hover",CHAN_AUTO,CHANF_UI);
			}
		}
		//keep track of slots we're hovering over:
		if (command == "CardSlot") {
			if (!unhovered)
				hoveredslot = PKCCardSlot(Caller);
			else
				hoveredslot = null;
		}
		if (command == "HandleCard") {
			let card = PKCCardButton(Caller);
			if (!unhovered)
				menu.HoveredCard = card;
			else
				menu.HoveredCard = null;
		}
	}
}

Class PK_BoardElementsHandler : StaticEventHandler {
}

Class PK_BoardEventHandler : EventHandler {
	ui bool boardOpened; //whether the Black Tarot board has been opened on this map
	
	/*override void WorldThingSpawned(Worldevent e) {
		if (e.thing && e.thing == players[consoleplayer].mo)
			Menu.SetMenu("PKCardsMenu");
	}*/	
	
	override void NetworkProcess(consoleevent e) {
		if (e.name.IndexOf("PKCUnlockCard") < 0)
			return;
		if (e.isManual || e.Player < 0)
			return;
		let plr = players[e.Player].mo;
		if (!plr)
			return;
		let goldcontrol = PK_CardControl(plr.FindInventory("PK_CardControl"));
		if (!goldcontrol)
			return;
		Array <String> cardname;
		e.name.split(cardname, ":");
		if (cardname.Size() == 0)
			return;
		bool cardtype = Clamp(e.args[0],0,1);
		//console.printf("pushing %s into the array",cardname[1]);
		goldcontrol.UnlockedTarotCards.Push(int(name(cardname[1])));
	}
}