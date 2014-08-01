# Homepage (Root path)
get '/' do
  erb :index
end

get '/:username' do
  name = params[:username]
  if !user_exists?(name)
    User.create(username: name)
  end
  @user = User.find_by(username: name)
  erb :'/users/index'
end

get '/:username/' do
  redirect :"/#{params[:username]}"
end

get '/:username/search' do
  @search_array = params[:search_string].split(" ")
  name = params[:username]
  @user = User.find_by(username: name)

  @search_results = []

  @search_array.each do | search_string |
    @matcher = search_string
    search_users_bookmarks
  end

  @search_results

  erb :'users/search'
end

get '/:username/collections/:collection' do

  name = params[:username]
  @user = User.find_by(username: name)
  @collection = params[:collection]
  erb :'/users/index'

end

post '/:username/bookmarks/delete' do
  name = params[:username]
  @user = User.find_by(username: name)

  bookmark = Bookmark.find_by(url: params[:url])
  users_bookmark = BookmarksUser.where(user_id: @user.id).where(bookmark_id: bookmark.id).first
  users_bookmark.destroy

  redirect :"/#{params[:username]}"
end

post '/:username' do
  name = params[:username]
  @user = User.find_by(username: name)

  # Append the http:// if it does not exist in the submitted url
  url = append_http(params[:url])

  # If url does not exist in Bookmark table, create it
  if Bookmark.find_by(url: url).nil?

    page = Nokogiri::HTML(open(url))

    # if nokogiri parses in an empty title, set title = url
    title = get_title(page)
    title = url if title.empty?

    bookmark = Bookmark.create(url: url, title: title, keywords: get_keywords(page), desc: get_desc(page))

  else
    bookmark = Bookmark.find_by(url: url)
  end

  # If user already bookmarked it...
  if BookmarksUser.where(user_id: @user.id).where(bookmark_id: bookmark.id).first
    @existing_bookmark = bookmark
    # I want it to stop here and show the error. i.e. Don't proceed to add it to the user's bookmarks.
  else
    # Add to the user's list of bookmarks
    @user.bookmarks << bookmark

    # Select the user's bookmark
    users_bookmark = BookmarksUser.where(user_id: @user.id).where(bookmark_id: bookmark.id).first

    # Array of collections from the "add" form
    submitted_collections = params[:collection].uniq

    # Go through each collection name
    submitted_collections.each do |collection|

      # Check if a collection was passed. If it's empty, then assign it to "uncategorized"
      if collection == ""
        collection = Collection.find(1)
      else
        # If a collection was passed, check if it already exists
        if collection_exists?(collection)
          collection = Collection.find_by(name: collection)
        else
          # Otherwise create the new collection
          collection = Collection.create(name: collection)
        end
      end
      users_bookmark.collections << collection
    end
  end

  erb :'/users/index'
end
