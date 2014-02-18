require 'spec_helper'

describe "Intercom::UserEvent" do
  
  let (:user) {Intercom::User.new("email" => "jim@example.com", :user_id => "12345", :created_at => Time.now, :name => "Jim Bob")}
  let (:created_time) {Time.now - 300}
  
  it "creates a user event" do
    Intercom.expects(:post).with("/events",
                                 { :type => 'event.list',
                                   :data => [ {:event_name => "signup", :created => created_time.to_i, :user => { :user_id => user.user_id}
                                    }]}).returns(:status => 200)

    Intercom::UserEvent.create({ :event_name => "signup", :user => user, :created => created_time })
  end

  it 'automatically adds a created time upon creation' do
    Intercom.expects(:post).with("/events",
                                 { :type => 'event.list',
                                   :data => [ {:event_name => "sale of item", :created => Time.now.to_i, :user => { :user_id => user.user_id}
                                    }]}).returns(:status => 200)
    
    Intercom::UserEvent.create({ :event_name => "sale of item", :user => user })
  end
  
  it "creates a user event with metadata" do
    Intercom.expects(:post).with("/events",
                                 { :type => 'event.list',
                                   :data => [ {:event_name => "signup", :created => created_time.to_i, :user => { :user_id => user.user_id}, :metadata => { :something => "here"}
                                    }]}).returns(:status => 200)
    Intercom::UserEvent.create({ :event_name => "signup", :user => user, :created => created_time, :metadata => { :something => "here"} })
  end

  it 'fails when no user supplied' do
    user_event = Intercom::UserEvent.new
    user_event.event_name = "some event"
    user_event.created = Time.now
    proc { user_event.save }.must_raise ArgumentError, "Missing User"
  end
  
  describe 'while batching events' do
    
    let (:event1) do
      user_event = Intercom::UserEvent.new
      user_event.event_name = "first event"
      user_event.created = Time.now
      user_event.user = user
      user_event
    end

    let (:event2) do
      user_event = Intercom::UserEvent.new
      user_event.event_name = "second event"
      user_event.created = Time.now
      user_event
    end
    
    it 'creates batched events' do
      Intercom.expects(:post).with("/events",
                                   { :type => 'event.list',
                                     :data => [ 
                                         {:event_name => "first event", :created => event1.created.to_i,
                                          :user => {:user_id => user.user_id}},
                                         {:event_name => "second event", :created => event2.created.to_i },
                                     ],
                                     :user => { :user_id => user.user_id}}).returns(:status => 200)
      Intercom::UserEvent.save_batch_events([event1, event2], user)
    end
  end
end
