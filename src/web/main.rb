module TINYmoirai::Web
  class Main < TINYmoirai::Web::Base
    get '/' do

      user = begin
                TINYmoirai::GithubAuthenticator.new(session)
              rescue TINYmoirai::GithubAuthenticator::Unauthorized
                redirect '/login'
              end

      @email = user.email
      @public_key = user.public_key

      slim :index
    end

    post '/export' do
      user = TINYmoirai::GithubAuthenticator.new(session)
      halt 403 unless user.valid?

      TINYmoirai::Export::Engage.new.execute do|exporter|
        exporter.execute(user.email, user.public_key)
      end

      redirect '/'
    end

    get '/login' do
      redirect ::TINYmoirai::GithubAuthenticator.login_url
    end

    get '/logout' do
      ::TINYmoirai::GithubAuthenticator.logout(session)
      redirect '/'
    end

    get '/callback' do
      TINYmoirai::GithubAuthenticator.authenticate(session,
                                                   request.env['rack.request.query_hash']['code'],
                                                   -> { redirect '/' },
                                                   -> { halt 403 })
    end
  end
end
