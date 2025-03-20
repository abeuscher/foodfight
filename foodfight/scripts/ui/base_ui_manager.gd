# Ensure the class_name is loaded for proper resolution
class_name BaseUIManager
extends BaseUIListener

signal title_screen_completed

# Core UI element references
var top_bar_panel
var bottom_bar_panel
var title_screen

# References to components
var weapon_placement
var player_manager
var weapon_manager
var targeting_state
var targeting_manager
var weapon_types
var main_scene
var game_state_machine
var turn_manager
var ai_controller

# Child UI managers
var player_ui_manager
var phase_ui_manager
var placement_ui_manager
var targeting_ui_manager
var ai_ui_manager

# Initialization flag
var is_initialized = false
var is_initializing = false

# Recursion guards - class level tracking of active method calls
var _active_method_calls = {}

# UI visibility state tracking
var _ui_states = {
    "weapon_buttons_visible": false,
    "targeting_buttons_visible": false,
    "end_placement_visible": false,
    "end_targeting_visible": false
}

func _ready():
    # Call parent ready first, which will register events
    super._ready()
    
    # Mark that initialization has started
    is_initializing = true
    print("BaseUIManager: Starting initialization")
    
    # Wait a frame to ensure all nodes are ready
    await get_tree().process_frame
    
    # Get reference to main scene
    _initialize_scene_references()
    
    # Create child UI managers
    _initialize_child_managers()
    
    # Initialize child manager dependencies
    _initialize_child_manager_dependencies()
    
    # Do a final check for any missing components
    _ensure_game_components()
    
    is_initialized = true
    is_initializing = false
    print("Base UI Manager initialized")
    
    # Register self as BaseUIManager service
    if Engine.has_singleton("GameManager"):
        var game_manager = Engine.get_singleton("GameManager")
        game_manager.register_service("BaseUIManager", self)
        print("BaseUIManager registered as BaseUIManager service")
        
        # Also register child managers as services
        if phase_ui_manager:
            game_manager.register_service("PhaseUIManager", phase_ui_manager)
        if player_ui_manager:
            game_manager.register_service("PlayerUIManager", player_ui_manager)
        if placement_ui_manager:
            game_manager.register_service("PlacementUIManager", placement_ui_manager)
        
        # Initialize placement state with weapon buttons container
        var placement_state = game_manager.get_service("PlacementState")
        var weapon_buttons_container = get_weapon_buttons_container()
        
        if placement_state and weapon_buttons_container:
            print("BaseUIManager: Registering weapon buttons container with PlacementState")
            if not placement_state.weapon_buttons_container:
                # Only update if not already set
                placement_state.weapon_buttons_container = weapon_buttons_container

# Initialize references to scene nodes
func _initialize_scene_references():
    # First try to get parent as main scene
    main_scene = get_parent()
    
    # Get reference to game state machine (try from parent first, then try global)
    game_state_machine = main_scene.get_node_or_null("GameStateMachine")
    if !game_state_machine and Engine.has_singleton("GameManager"):
        var GameManager = Engine.get_singleton("GameManager")
        game_state_machine = GameManager.game_state_machine
    
    # Get UI references from scene tree
    var root = get_tree().get_root()
    var main_node = root.get_node_or_null("Main")
    
    if main_node:
        # Get top and bottom bar elements
        top_bar_panel = main_node.get_node_or_null("UI/TopBar")
        bottom_bar_panel = main_node.get_node_or_null("UI/BottomBar")
        
        # Get title screen
        title_screen = main_node.get_node_or_null("UI/TitleScreen")
        if title_screen and title_screen.has_signal("animation_completed"):
            if !title_screen.is_connected("animation_completed", Callable(self, "_on_title_screen_animation_completed")):
                title_screen.connect("animation_completed", Callable(self, "_on_title_screen_animation_completed"))
        else:
            print("BaseUIManager: Title screen not found or doesn't have animation_completed signal")
    
    # Get references to other nodes from both main_scene and main_node
    for node_source in [main_scene, main_node]:
        if node_source:
            if !weapon_placement and node_source.has_node("WeaponPlacement"):
                weapon_placement = node_source.get_node("WeaponPlacement")
            
            if !player_manager and node_source.has_node("PlayerManager"):
                player_manager = node_source.get_node("PlayerManager")
            
            if !weapon_types and node_source.has_node("WeaponTypes"):
                weapon_types = node_source.get_node("WeaponTypes")

# Initialize child UI manager components
func _initialize_child_managers():
    print("====== CRITICAL DEBUG: Creating UI manager children ======")
    
    # Create player UI manager if not exists
    if !player_ui_manager:
        player_ui_manager = Node.new()
        player_ui_manager.name = "PlayerUIManager"
        player_ui_manager.set_script(load("res://scripts/ui/player_ui_manager.gd"))
        add_child(player_ui_manager)
    
    # Create phase UI manager if not exists
    if !phase_ui_manager:
        print("  - Creating new PhaseUIManager")
        phase_ui_manager = Node.new()
        phase_ui_manager.name = "PhaseUIManager"
        phase_ui_manager.set_script(load("res://scripts/ui/phase_ui_manager.gd"))
        add_child(phase_ui_manager)
    else:
        print("  - PhaseUIManager already exists")
    
    # Create placement UI manager if not exists
    if !placement_ui_manager:
        placement_ui_manager = Node.new()
        placement_ui_manager.name = "PlacementUIManager"
        placement_ui_manager.set_script(load("res://scripts/ui/placement_ui_manager.gd"))
        add_child(placement_ui_manager)
    
    # Create targeting UI manager if not exists
    if !targeting_ui_manager:
        targeting_ui_manager = Node.new()
        targeting_ui_manager.name = "TargetingUIManager"
        targeting_ui_manager.set_script(load("res://scripts/ui/targeting_ui_manager.gd"))
        add_child(targeting_ui_manager)
    
    # Create AI UI manager if not exists
    if !ai_ui_manager:
        ai_ui_manager = Node.new()
        ai_ui_manager.name = "AIUIManager"
        ai_ui_manager.set_script(load("res://scripts/ai/ai_ui_manager.gd"))
        add_child(ai_ui_manager)

# Initialize dependencies for child managers
func _initialize_child_manager_dependencies():
    print("====== CRITICAL DEBUG: Initializing UI child dependencies ======")
    
    # Find the main scene - try multiple approaches
    var ui_container_node = null
    var root = get_tree().get_root()
    var main_node = root.get_node_or_null("Main")
    
    if main_node:
        ui_container_node = main_node
    elif main_scene:
        ui_container_node = main_scene
    
    if ui_container_node:
        # Setup player UI manager
        var p1_name_label = ui_container_node.get_node_or_null("UI/TopBar/HBoxContainer/Player1Container/NameLabel")
        var p2_name_label = ui_container_node.get_node_or_null("UI/TopBar/HBoxContainer/Player2Container/NameLabel")
        var p1_score_label = ui_container_node.get_node_or_null("UI/TopBar/HBoxContainer/Player1Container/ScoreLabel")
        var p2_score_label = ui_container_node.get_node_or_null("UI/TopBar/HBoxContainer/Player2Container/ScoreLabel")
        
        if player_ui_manager:
            player_ui_manager.initialize(p1_name_label, p2_name_label, p1_score_label, p2_score_label, player_manager)
        
        # Setup phase UI manager
        var turn_label = ui_container_node.get_node_or_null("UI/TopBar/HBoxContainer/PhaseContainer/TurnLabel")
        var phase_label = ui_container_node.get_node_or_null("UI/TopBar/HBoxContainer/PhaseContainer/PhaseLabel")
        
        if phase_ui_manager:
            print("  - Initializing PhaseUIManager")
            print("    - turn_label: " + ("FOUND" if turn_label else "MISSING"))
            print("    - phase_label: " + ("FOUND" if phase_label else "MISSING"))
            print("    - title_screen: " + ("FOUND" if title_screen else "MISSING"))
            print("    - player_manager: " + ("FOUND" if player_manager else "MISSING"))
            
            phase_ui_manager.initialize(turn_label, phase_label, title_screen, player_manager)
            print("  - PhaseUIManager initialized")
            print("  - Has update_phase_ui: " + str(phase_ui_manager.has_method("update_phase_ui")))
            
            # Ensure it's registered directly as well
            if Engine.has_singleton("GameManager"):
                print("  - Registering PhaseUIManager directly")
                Engine.get_singleton("GameManager").register_service("PhaseUIManager", phase_ui_manager)
        else:
            print("  - ERROR: PhaseUIManager is null, cannot initialize!")
        
        # Setup placement UI manager with more detailed logging
        var weapon_buttons_container = ui_container_node.get_node_or_null("UI/BottomBar/WeaponButtonsContainer")
        var end_placement_button = ui_container_node.get_node_or_null("UI/BottomBar/EndPlacementButton")
        
        print("  - Setup placement UI: weapon_buttons_container=" + ("FOUND" if weapon_buttons_container else "MISSING") + 
             ", end_placement_button=" + ("FOUND" if end_placement_button else "MISSING"))
        
        if placement_ui_manager:
            print("  - Initializing PlacementUIManager")
            placement_ui_manager.initialize(weapon_buttons_container, end_placement_button, 
                weapon_placement, weapon_types, player_manager, ui_container_node)
            print("  - PlacementUIManager initialized")
            
            # Register it as service
            if Engine.has_singleton("GameManager"):
                Engine.get_singleton("GameManager").register_service("PlacementUIManager", placement_ui_manager)
        else:
            print("  - ERROR: PlacementUIManager is null, cannot initialize!")
        
        # Also share weapon button container with placement state directly
        if Engine.has_singleton("GameManager"):
            var placement_state = Engine.get_singleton("GameManager").get_service("PlacementState")
            if placement_state and weapon_buttons_container:
                if placement_state.has_method("initialize"):
                    # If not yet initialized, initialize it
                    if !placement_state.weapon_buttons_container:
                        print("  - Initializing PlacementState with UI components")
                        var weapon_types_service = Engine.get_singleton("GameManager").get_service("WeaponTypes")
                        var weapon_placement_service = Engine.get_singleton("GameManager").get_service("WeaponPlacement")
                        placement_state.initialize(weapon_types_service, weapon_placement_service, weapon_buttons_container)
                else:
                    # Direct property update if already initialized
                    placement_state.weapon_buttons_container = weapon_buttons_container
        
        # Setup targeting UI manager
        var targeting_buttons_container = ui_container_node.get_node_or_null("UI/BottomBar/TargetingButtonsContainer")
        var end_targeting_button = ui_container_node.get_node_or_null("UI/BottomBar/EndTargetingButton")
        
        if targeting_ui_manager:
            targeting_ui_manager.initialize(targeting_buttons_container, end_targeting_button,
                weapon_manager, targeting_manager, targeting_state, player_manager, ui_container_node)
        
        # Setup AI UI manager
        if ai_ui_manager:
            ai_ui_manager.initialize(ui_container_node)
    else:
        print("BaseUIManager: Could not find UI container node for initialization")

# Ensure all game components are available
func _ensure_game_components():
    # Try to get components from GameManager if available
    if Engine.has_singleton("GameManager"):
        var GameManager = Engine.get_singleton("GameManager")
        
        if !weapon_manager and GameManager.has_method("get_service"):
            weapon_manager = GameManager.get_service("WeaponManager")
        
        if !targeting_state and GameManager.has_method("get_service"):
            targeting_state = GameManager.get_service("TargetingState")
        
        if !targeting_manager and GameManager.has_method("get_service"):
            targeting_manager = GameManager.get_service("TargetingManager")
        
        if !weapon_types and GameManager.has_method("get_service"):
            weapon_types = GameManager.get_service("WeaponTypes")
        
        if !turn_manager and GameManager.has_method("get_service"):
            turn_manager = GameManager.get_service("TurnManager")
        
        if !ai_controller and GameManager.has_method("get_service"):
            ai_controller = GameManager.get_service("AIController")
            
        if !game_state_machine and GameManager.has_method("get_service"):
            game_state_machine = GameManager.get_service("GameStateMachine")
        
        # Fallback to older methods if service locator is not yet fully implemented
        if !weapon_manager and GameManager.has_method("get_weapon_manager"):
            weapon_manager = GameManager.get_weapon_manager()
            
        if !targeting_state and GameManager.has_method("get_targeting_state"):
            targeting_state = GameManager.get_targeting_state()
            
        if !targeting_manager and GameManager.has_method("get_targeting_manager"):
            targeting_manager = GameManager.get_targeting_manager()
            
        if !weapon_types and GameManager.has_method("get_weapon_types"):
            weapon_types = GameManager.get_weapon_types()
            
        if !turn_manager and GameManager.has_method("get_turn_manager"):
            turn_manager = GameManager.get_turn_manager()
            
        if !ai_controller and GameManager.has_method("get_ai_controller"):
            ai_controller = GameManager.get_ai_controller()
            
        if !game_state_machine and GameManager.has_method("get_game_state_machine"):
            game_state_machine = GameManager.get_game_state_machine()
        
        # Fallback to direct field access as last resort
        if !weapon_manager and "weapon_manager" in GameManager:
            weapon_manager = GameManager.weapon_manager
            
        if !targeting_state and "targeting_state" in GameManager:
            targeting_state = GameManager.targeting_state
            
        if !targeting_manager and "targeting_manager" in GameManager:
            targeting_manager = GameManager.targeting_manager
            
        if !weapon_types and "weapon_types" in GameManager:
            weapon_types = GameManager.weapon_types
            
        if !turn_manager and "turn_manager" in GameManager:
            turn_manager = GameManager.turn_manager
            
        if !ai_controller and "ai_controller" in GameManager:
            ai_controller = GameManager.ai_controller
            
        if !game_state_machine and "game_state_machine" in GameManager:
            game_state_machine = GameManager.game_state_machine
    
    # Update dependencies for child managers
    _update_child_manager_dependencies()

# Update dependencies in child managers with additional checks 
func _update_child_manager_dependencies():
    if player_ui_manager and player_manager:
        player_ui_manager.player_manager = player_manager
    
    if phase_ui_manager and player_manager:
        phase_ui_manager.player_manager = player_manager
    
    if placement_ui_manager:
        if weapon_placement:
            placement_ui_manager.weapon_placement = weapon_placement
        if weapon_types:
            placement_ui_manager.weapon_types = weapon_types
        if player_manager:
            placement_ui_manager.player_manager = player_manager
    
    if targeting_ui_manager:
        if weapon_manager:
            targeting_ui_manager.weapon_manager = weapon_manager
        if targeting_manager:
            targeting_ui_manager.targeting_manager = targeting_manager
        if targeting_state:
            targeting_ui_manager.targeting_state = targeting_state
        if player_manager:
            targeting_ui_manager.player_manager = player_manager
    
    # Ensure PlacementState has the correct weapon buttons container
    var placement_state = get_service("PlacementState")
    var weapon_buttons_container = get_weapon_buttons_container()
    
    if placement_state and weapon_buttons_container:
        if !placement_state.weapon_buttons_container:
            print("BaseUIManager: Updating PlacementState with weapon_buttons_container")
            placement_state.weapon_buttons_container = weapon_buttons_container

# Helper to get weapon buttons container
func get_weapon_buttons_container():
    var root = get_tree().get_root()
    var main_node = root.get_node_or_null("Main")
    
    if main_node:
        return main_node.get_node_or_null("UI/BottomBar/WeaponButtonsContainer")
    return null

# Handle title screen animation completed
func _on_title_screen_animation_completed():
    emit_signal("title_screen_completed")
    emit_event(GameEvents.TITLE_SCREEN_COMPLETED)

# Event handlers
func on_ui_update_required(event_data):
    update_ui(event_data.state, event_data.player_index)
    
func on_phase_changed(event_data):
    update_game_phase(event_data.phase_text)
    
func on_player_changed(event_data):
    update_player_ui(event_data.player_index)
    
func on_ai_thinking_started(_event_data = null):
    if _active_method_calls.has("on_ai_thinking_started") and _active_method_calls["on_ai_thinking_started"]:
        return
        
    _active_method_calls["on_ai_thinking_started"] = true
    show_ai_thinking()
    _active_method_calls["on_ai_thinking_started"] = false
    
func on_ai_thinking_completed(_event_data = null):
    if _active_method_calls.has("on_ai_thinking_completed") and _active_method_calls["on_ai_thinking_completed"]:
        return
        
    _active_method_calls["on_ai_thinking_completed"] = true
    # Enhanced debug to help track this event
    print("BaseUIManager: on_ai_thinking_completed called")
    hide_ai_thinking()
    _active_method_calls["on_ai_thinking_completed"] = false
    
func on_game_over(event_data):
    show_game_over(event_data.winning_player)
    
func on_state_changed(event_data):
    print("BaseUIManager: Handling STATE_CHANGED event: " + str(event_data))
    update_ui(event_data.new_state, event_data.player_index)
    
    # Explicitly trigger placement state UI update for weapon placement
    if event_data.new_state == 3: # WEAPON_PLACEMENT
        var placement_state = get_service("PlacementState")
        if placement_state and placement_state.has_method("create_weapon_buttons_for_current_state"):
            print("BaseUIManager: Explicitly triggering weapon button creation")
            placement_state.create_weapon_buttons_for_current_state()
            
            # Make sure container is visible
            var weapon_buttons_container = get_weapon_buttons_container()
            if weapon_buttons_container:
                weapon_buttons_container.visible = true
                if weapon_buttons_container.get_parent():
                    weapon_buttons_container.get_parent().visible = true

# Getter for phase_ui_manager to maintain API compatibility
func get_phase_ui_manager():
    return phase_ui_manager

# Method to safely call a function with fallbacks - FIXED RECURSION ISSUE
func _safe_ui_call(method_name, args = []):
    # Check if we're already processing this method to prevent recursion
    if _active_method_calls.has(method_name) and _active_method_calls[method_name]:
        push_warning("BaseUIManager: Breaking recursive call cycle for method: " + method_name)
        return null
    
    # Mark this method as being processed
    _active_method_calls[method_name] = true
    
    # Track result to return after cleaning up
    var result = null
    
    # Determine which manager should handle this method
    var manager_name = null
    
    if method_name in ["update_player_ui", "update_ingredients_display"]:
        manager_name = "player_ui_manager"
    elif method_name in ["update_game_phase", "update_current_turn", "show_phase_title", "show_game_over", "update_phase_ui"]:
        manager_name = "phase_ui_manager"
    elif method_name in ["show_ai_thinking", "hide_ai_thinking"]:
        manager_name = "ai_ui_manager"
    elif method_name in ["update_weapon_placement_ui", "update_base_placement_ui"]:
        manager_name = "placement_ui_manager"
    elif method_name in ["update_targeting_ui"]:
        manager_name = "targeting_ui_manager"
    
    if manager_name:
        var manager = get(manager_name)
        if manager and manager.has_method(method_name):
            result = _call_with_args(manager, method_name, args)
    
    # Clear the recursion guard for this method
    _active_method_calls[method_name] = false
    
    return result

# Helper to call a method with variable number of arguments
func _call_with_args(object, method_name, args):
    match args.size():
        0: return object.call(method_name)
        1: return object.call(method_name, args[0])
        2: return object.call(method_name, args[0], args[1])
        3: return object.call(method_name, args[0], args[1], args[2])
        _: 
            push_warning("BaseUIManager: Unsupported argument count for " + method_name)
            return null

# Update the update_ui method to explicitly handle weapon placement
func update_ui(current_state, current_player_index):
    # Check for recursion
    if _active_method_calls.has("update_ui") and _active_method_calls["update_ui"]:
        print("BaseUIManager: Breaking recursive update_ui call - state:", current_state, "player:", current_player_index)
        return
    
    _active_method_calls["update_ui"] = true
    
    if !is_initialized and !is_initializing:
        print("BaseUIManager: Not initialized yet, waiting a frame")
        await get_tree().process_frame
    
    print("BaseUIManager: Updating UI for state " + str(current_state) + " for player " + str(current_player_index + 1))
    
    # Ensure we have game components
    _ensure_game_components()
    
    # Update player UI directly
    if player_ui_manager and player_ui_manager.has_method("update_player_ui"):
        player_ui_manager.update_player_ui(current_player_index)
    
    # Update phase UI directly
    if phase_ui_manager and phase_ui_manager.has_method("update_phase_ui"):
        phase_ui_manager.update_phase_ui(current_state, current_player_index)
    
    # Update state-specific UI based on current state
    if game_state_machine:
        match current_state:
            game_state_machine.GameState.BASE_PLACEMENT:
                if placement_ui_manager and placement_ui_manager.has_method("update_base_placement_ui"):
                    placement_ui_manager.update_base_placement_ui(current_state, current_player_index)
                
                # Direct UI handling in case placement_ui_manager fails
                _ensure_ui_element_visibility("weapon_buttons_container", true)
                _ensure_ui_element_visibility("end_placement_button", true)
                
                # Make sure placement state has the correct buttons
                var placement_state = get_service("PlacementState")
                var weapon_buttons_container = get_weapon_buttons_container()
                if placement_state and weapon_buttons_container and placement_state.has_method("create_weapon_buttons_for_current_state"):
                    placement_state.weapon_buttons_container = weapon_buttons_container
                    placement_state.create_weapon_buttons_for_current_state()
            
            game_state_machine.GameState.WEAPON_PLACEMENT:
                if placement_ui_manager and placement_ui_manager.has_method("update_weapon_placement_ui"):
                    # Ensure this is always called when in weapon placement state
                    print("BaseUIManager: Explicitly updating weapon placement UI")
                    placement_ui_manager.update_weapon_placement_ui(current_state, current_player_index)
                
                # Direct UI handling in case placement_ui_manager fails
                _ensure_ui_element_visibility("weapon_buttons_container", true)
                _ensure_ui_element_visibility("end_placement_button", true)
                
                # Make sure placement state has the correct buttons and updates them
                var placement_state = get_service("PlacementState")
                var weapon_buttons_container = get_weapon_buttons_container()
                if placement_state and weapon_buttons_container and placement_state.has_method("create_weapon_buttons_for_current_state"):
                    placement_state.weapon_buttons_container = weapon_buttons_container
                    placement_state.create_weapon_buttons_for_current_state()
            
            game_state_machine.GameState.TARGETING:
                if targeting_ui_manager and targeting_ui_manager.has_method("update_targeting_ui"):
                    targeting_ui_manager.update_targeting_ui(current_state, current_player_index)
                
                # Direct UI handling in case targeting_ui_manager fails
                _ensure_ui_element_visibility("weapon_buttons_container", false)
                _ensure_ui_element_visibility("targeting_buttons_container", true)
                _ensure_ui_element_visibility("end_targeting_button", true)
    
    # For AI turns, show thinking indicator - direct calls
    var is_ai_turn = (current_player_index == 1)
    if is_ai_turn:
        if ai_ui_manager and ai_ui_manager.has_method("show_ai_thinking"):
            ai_ui_manager.show_ai_thinking()
    else:
        if ai_ui_manager and ai_ui_manager.has_method("hide_ai_thinking"):
            ai_ui_manager.hide_ai_thinking()
    
    # Clear recursion guard
    _active_method_calls["update_ui"] = false

# Helper to ensure UI element visibility
func _ensure_ui_element_visibility(element_name, visible):
    var element = null
    var root = get_tree().get_root()
    var main_node = root.get_node_or_null("Main")
    
    if main_node:
        match element_name:
            "weapon_buttons_container":
                element = main_node.get_node_or_null("UI/BottomBar/WeaponButtonsContainer")
            "targeting_buttons_container":
                element = main_node.get_node_or_null("UI/BottomBar/TargetingButtonsContainer")
            "end_placement_button":
                element = main_node.get_node_or_null("UI/BottomBar/EndPlacementButton")
            "end_targeting_button":
                element = main_node.get_node_or_null("UI/BottomBar/EndTargetingButton")
    
    if element:
        if element.visible != visible:
            print("BaseUIManager: Setting " + element_name + " visibility to " + str(visible))
            element.visible = visible
            
            # For containers, also ensure parent is visible
            if element_name.ends_with("_container") and element.get_parent():
                element.get_parent().visible = visible
        
        # Track state
        _ui_states[element_name + "_visible"] = visible

# Forward methods to appropriate child managers - add recursion guards
func handle_player_turn_update(player_index):
    if _active_method_calls.has("handle_player_turn_update") and _active_method_calls["handle_player_turn_update"]:
        return
        
    _active_method_calls["handle_player_turn_update"] = true
    
    if !player_manager:
        print("BaseUIManager: Missing player_manager for turn update")
        _active_method_calls["handle_player_turn_update"] = false
        return
        
    if phase_ui_manager and phase_ui_manager.has_method("update_current_turn"):
        phase_ui_manager.update_current_turn(player_manager.get_player_name(player_index))
    
    _active_method_calls["handle_player_turn_update"] = false

# Show AI thinking indicator (forwarded to AI UI manager)
func show_ai_thinking():
    if _active_method_calls.has("show_ai_thinking") and _active_method_calls["show_ai_thinking"]:
        print("BaseUIManager: Breaking recursive show_ai_thinking call")
        return
        
    _active_method_calls["show_ai_thinking"] = true
    
    if ai_ui_manager and ai_ui_manager.has_method("show_ai_thinking"):
        ai_ui_manager.show_ai_thinking()
    
    # Emit event after delegating to AI UI manager - ONLY if we're not already handling an event
    if !_active_method_calls.get("on_ai_thinking_started", false):
        emit_event(GameEvents.AI_THINKING_STARTED)
    
    _active_method_calls["show_ai_thinking"] = false

# Hide AI thinking indicator (forwarded to AI UI manager)
func hide_ai_thinking():
    if _active_method_calls.has("hide_ai_thinking") and _active_method_calls["hide_ai_thinking"]:
        print("BaseUIManager: Breaking recursive hide_ai_thinking call")
        return
        
    _active_method_calls["hide_ai_thinking"] = true
    
    if ai_ui_manager and ai_ui_manager.has_method("hide_ai_thinking"):
        ai_ui_manager.hide_ai_thinking()
    
    # Emit event after delegating to AI UI manager - ONLY if we're not already handling an event
    if !_active_method_calls.get("on_ai_thinking_completed", false):
        emit_event(GameEvents.AI_THINKING_COMPLETED)
    
    _active_method_calls["hide_ai_thinking"] = false

# Update game phase (forwarded to phase UI manager)
func update_game_phase(phase_text):
    if _active_method_calls.has("update_game_phase") and _active_method_calls["update_game_phase"]:
        return
        
    _active_method_calls["update_game_phase"] = true
    
    if phase_ui_manager and phase_ui_manager.has_method("update_game_phase"):
        phase_ui_manager.update_game_phase(phase_text)
    
    _active_method_calls["update_game_phase"] = false

# Update current turn label (forwarded to phase UI manager)
func update_current_turn(player_name):
    if _active_method_calls.has("update_current_turn") and _active_method_calls["update_current_turn"]:
        return
        
    _active_method_calls["update_current_turn"] = true
    
    if phase_ui_manager and phase_ui_manager.has_method("update_current_turn"):
        phase_ui_manager.update_current_turn(player_name)
    
    _active_method_calls["update_current_turn"] = false

# Update player UI (forwarded to player UI manager) - Added for API compatibility
func update_player_ui(player_index):
    if _active_method_calls.has("update_player_ui") and _active_method_calls["update_player_ui"]:
        return
        
    _active_method_calls["update_player_ui"] = true
    
    if player_ui_manager and player_ui_manager.has_method("update_player_ui"):
        player_ui_manager.update_player_ui(player_index)
    
    _active_method_calls["update_player_ui"] = false

# Show game over screen (forwarded to phase UI manager)
func show_game_over(winning_player):
    if _active_method_calls.has("show_game_over") and _active_method_calls["show_game_over"]:
        return
        
    _active_method_calls["show_game_over"] = true
    
    if phase_ui_manager and phase_ui_manager.has_method("show_game_over"):
        phase_ui_manager.show_game_over(winning_player)
    
    _active_method_calls["show_game_over"] = false

# Connect signals from AI opponent - Added for API compatibility
func connect_ai_signals(ai_opponent):
    if ai_opponent and ai_ui_manager and ai_ui_manager.has_method("connect_ai_signals"):
        ai_ui_manager.connect_ai_signals(ai_opponent)

# Helper to get a service - use proper service locator pattern
func get_service(service_name):
    if Engine.has_singleton("GameManager"):
        return Engine.get_singleton("GameManager").get_service(service_name)
    return null

# Method to handle deferred initialization and update - Added for API compatibility
func initialize_managers_and_update(state, player_index):
    print("BaseUIManager: Deferred initialization and update")
    if !is_initialized:
        await get_tree().process_frame  # Just waiting one frame, since our initialization is synchronous
    
    # Now try again with initialized managers
    update_ui(state, player_index)

# Method to initialize managers - Added for API compatibility
func initialize_managers():
    # Does nothing since initialization happens in _ready()
    # Kept for API compatibility
    return
