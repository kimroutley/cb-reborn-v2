    # In the project root:
    cd packages/cb_models
    dart run build_runner build --delete-conflicting-outputs

    cd ../cb_logic
    dart run build_runner build --delete-conflicting-outputs

    cd ../cb_theme # If it has any build_runner dependencies (e.g. for Freezed in models)
    dart run build_runner build --delete-conflicting-outputs
    
    cd ../../apps/host
    dart run build_runner build --delete-conflicting-outputs
    
    cd ../../apps/player
    dart run build_runner build --delete-conflicting-outputs
    