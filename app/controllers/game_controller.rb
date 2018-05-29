MAPWIDTH = 15
MAPHEIGHT = 10

class GameController < ApplicationController

  def view
    @team = session[:team]
    @territoryMap = Map.find(1)
    @resourceMap = Map.find(2)
    @personMap = Map.find(3)
  end

  def edit
    # Users without admin perms are not allowed to view edit page.
    # Code below reinforces this.
    if session[:team] != 0
      redirect_to :controller=>'sessions',:action=>'new'
    end
    @territoryMap = Map.find(1)
    @resourceMap = Map.find(2)
    @personMap = Map.find(3)
    @selector = nil
    (params[:buttonSelector].to_s.to_i(2))
    if ()
      @selector = "000000000"
    else
      @selector = params[:buttonSelector].to_s.to_i(2)
    end
  end
  
  def create
    # Users without admin perms are not allowed to view create account page.
    # Code below reinforces this.
    if session[:team] != 0
      redirect_to :controller=>'sessions',:action=>'new'
    end
  end
  
  def randomize
    # Users without admin perms are not allowed to view randomize page.
    # Code below reinforces this.
    if session[:team] != 0
      redirect_to :controller=>'sessions',:action=>'new'
    end
  end
  
  def destroy
    # Users without admin perms are not allowed to view delete account page.
    # Code below reinforces this.
    if session[:team] != 0
      redirect_to :controller=>'sessions',:action=>'new'
    end
  end

  # Function to edit map info at [row, col] on map ID index using "new".
  # Returns true if success, else returns false.
  # Will be changed to flash messages if the edit fails.
  # Admin options will be provided to forcibly change the map if needed.
  def modify
    index = -1
    if params[:map][:newVal].to_i < 8
      index = 1
    end  
    if params[:map][:newVal].to_i > 7 && params[:map][:newVal].to_i < 15
      index = 2
    end
    if params[:map][:newVal].to_i > 14
      index = 3
    end
    map = Map.find(index)
    # Reconvert row and column.
    row = params[:map][:tileSelector][0].to_i(16)
    col = params[:map][:tileSelector][1].to_i(16)
    # Set the new value for the map data (if adding something)
    newVal = -1
    case index
    when 1
      newVal = params[:map][:newVal].to_i + 1
    when 2
      newVal = params[:map][:newVal].to_i - 7
    when 3
      newVal = params[:map][:newVal].to_i - 14
    # if index is somehow not valid, terminate- this code should NOT reach the map's data unless it is valid
    else
      flash[:notice] = "Operation failed, index invalid."
      
      redirect_to :controller=>'game',:action=>'edit' 
    end
    
    #prints intermediary variables to console
    puts ("Index: " + index.to_s + "\n")
    action = params[:map][:action].to_i
    puts ("Action: " + action.to_s + "\n")
    
    oldVal = map.data[(row * MAPWIDTH) + col].to_i
    
    puts ("Old tile: " + oldVal.to_s + "\n")
    puts ("Tile free? " + (oldVal == 0).to_s + "\n")
    
    # case "user wants to force-add object"
    if action == 2
      map.data[(row * MAPWIDTH) + col] = newVal.to_s
      #flash success
      puts ("Success \n")
      flash[notice] = "Operation completed succesfully."
    end
    # case "user wants to remove object"
    if action == 1
      map.data[(row * MAPWIDTH) + col] = '0'
      #flash success
      puts ("Success \n")
      flash[notice] = "Operation completed succesfully."
    end
    # "Soft adding" ignores action if it interrupts specific instructions (territory over territory, military over empty space, etc)
    if action == 0
      # Case adding tile
      if index == 1
        # If territory to be changed is enemy's and within 3 tiles of military, then fail.
        if (oldVal != 0 && oldVal != newVal)
          
          if militaryCheck(oldVal, (row * MAPWIDTH) + col)
            # flash failure
            puts ("Failure Military \n")
            flash[notice] = "Operation failed! Someone's military is too close!"
          else
            # flash failure, but with message that you can force it
            puts ("Failure Nonmilitary \n")
            flash[notice] = "Operation failed, but the tile is unguarded."
          end
        else
          # flash success
          map.data[(row * MAPWIDTH) + col] = newVal.to_s
          puts ("Success, territory added \n")
          flash[notice] = "Operation completed succesfully."
        end
      end
      # Case adding other
      if index == 2
        if oldVal == 0
          map.data[(row * MAPWIDTH) + col] = newVal.to_s
          puts ("Success, resource added \n")
          flash[notice] = "Operation completed succesfully."
        else
          flash[notice] = "Resource already exists on tile."
        end
      end
      if index == 3
        if oldVal == 0 && Map.find(1).data[(row * MAPWIDTH) + col].to_i != 0
          map.data[(row * MAPWIDTH) + col] = newVal.to_s
          puts ("Success, military added \n")
          flash[notice] = "Operation completed succesfully."
        else
          flash[notice] = "Unit already exists on tile, or attempted to place unit on unclaimed territory."
        end
      end
    end
    # prints info
    indexPlaced = (row * MAPWIDTH) + col
    puts ("New value: " + newVal.to_s + "\n")
    puts ("Full map: " + map.data.to_s + "\n")
    puts ("Index placed: " + indexPlaced.to_s)
    map.save
    redirect_to :controller=>'game',:action=>'edit',:buttonSelector=>params[:map][:buttonSelector]
    
  end
  
  #function to create a new user.
  def createUser
    @user = User.new()
    @user.team = params[:user][:team]
    @user.username = params[:user][:username]
    @user.password = params[:user][:password]
    if @user.save
      puts('Account created!')
    end
    redirect_to :controller=>'game',:action=>'edit'
  end
  
  #function to delete a user.
  def deleteUser
    user = User.find_by(username: params[:user][:username])
    if user != nil
      if user.authenticate(params[:user][:password])
        user.destroy
        puts('Account deletion successful.')
        flash.now[:notice] = 'Account deletion successful.'
        redirect_to :controller=>'game',:action=>'edit'
      else
        puts('Invalid password.')
        flash.now[:notice] = 'Invalid password.'
        redirect_to :controller=>'game',:action=>'edit'
      end
    else
      puts('Invalid account.')
      flash.now[:notice] = 'Invalid account.'
      redirect_to :controller=>'game',:action=>'edit'
    end
  end
  
  
  # function to set up new game
  def randomizeMap
    @territoryMap = Map.find(1)
    @resourceMap = Map.find(2)
    @personMap = Map.find(3)
    
    # Wipe persons and territory claims. 
    counter = 0
    @personMap.data.each_char do |each|
      @personMap.data[counter] = '0'
      @territoryMap.data[counter] = '0'
      counter += 1
    end
    # Init RNG.
    srand
    
    # Randomize resources.
    counter = 0
    @resourceMap.data.each_char do |each|
      @resourceMap.data[counter] = [rand(-20..6), 0].max.to_s
      counter += 1
    end
    
    # Create team spawnpoints.
    for i in 1..4
      newCapital = findNewCapital(@territoryMap.data)
      @resourceMap.data[newCapital] = '7'
      @territoryMap.data[newCapital] = i.to_s
      # @territoryMap.data[newCapital + 1] = i.to_s
      # @territoryMap.data[newCapital - 1] = i.to_s
      # @territoryMap.data[newCapital + MAPWIDTH] = i.to_s
      # @territoryMap.data[newCapital - MAPWIDTH] = i.to_s
      
      # @territoryMap.data[newCapital + MAPWIDTH + 1] = i.to_s
      # @territoryMap.data[newCapital - MAPWIDTH - 1] = i.to_s
      # @territoryMap.data[newCapital + MAPWIDTH - 1] = i.to_s
      # @territoryMap.data[newCapital - MAPWIDTH + 1] = i.to_s
    end
    
    puts ("New values: \n")
    puts (@territoryMap.data + "\n")
    puts (@resourceMap.data + "\n")
    puts (@personMap.data + "\n")
    
    @territoryMap.save
    @resourceMap.save
    @personMap.save
    
    redirect_to :controller=>'game',:action=>'edit'
  end
  
  # Finds a new capital at least 1 block away from all other claimed territory spots
  def findNewCapital(currentMap)
    srand
    while true
      newCapital = rand(1..MAPWIDTH - 2) + (MAPWIDTH * rand(1..MAPHEIGHT - 2))
      noBorders = true
      claimedTiles = Array.new
      counter = 0
      # Scan for other claimed tiles.
      # Current team's tiles irrelevant at this point since staking claim.
      currentMap.each_char do |each|
        if each.to_i != 0
          claimedTiles.push(counter)
          puts("Tile already claimed: " + counter.to_s + "\n")
        end
        counter += 1
      end
      # Ensure no tile is within 1 manhattan distance
      claimedTiles.each do |tile|
        vDistance = ((tile / MAPWIDTH) - (newCapital / MAPWIDTH)).abs
        hDistance = ((tile % MAPWIDTH) - (newCapital % MAPWIDTH)).abs
        distance = vDistance + hDistance
        if distance < 4
          noBorders = false
        end
      end
      if noBorders
        return newCapital
      end
    end
  end
  
  #function to check if military from "team" is three tiles from "init"
  def militaryCheck(team, init)
    territoryMap = Map.find(1).data
    militaryMap = Map.find(3).data
    puts ("Military map: " + militaryMap + "\n")
    
    # array of all military units
    unitList = Array.new
    
    # find all military units
    for i in 0..territoryMap.length()
      if territoryMap[i].to_i == team && militaryMap[i].to_i == 2
        puts ("Unit found! i: " + i.to_s + "\n")
        unitList.push(i)
      end
      
    end
    
    puts ("unitList: " + unitList.to_s + "\n")
    
    # find manhattan distance from each unit, if less than three return 0
    unitList.each do |unit|
      distance = ((unit % MAPWIDTH) - (init % MAPWIDTH)).abs + ((unit / MAPWIDTH) - (init / MAPWIDTH)).abs
      if distance < 4
        return true
      end
    end
    
    return false
  end
end
