require 'spec_helper'

describe "RailsAdmin Config" do
  include Warden::Test::Helpers

  before(:each) do
    RailsAdmin::AbstractModel.new("Division").destroy_all!
    RailsAdmin::AbstractModel.new("Draft").destroy_all!
    RailsAdmin::AbstractModel.new("Fan").destroy_all!
    RailsAdmin::AbstractModel.new("League").destroy_all!
    RailsAdmin::AbstractModel.new("Player").destroy_all!
    RailsAdmin::AbstractModel.new("Team").destroy_all!
    RailsAdmin::AbstractModel.new("User").destroy_all!

    user = RailsAdmin::AbstractModel.new("User").create(
      :email => "test@test.com",
      :password => "test1234"
    )

    login_as user
  end

  after(:each) do
    Warden.test_reset!
  end
  describe "config" do

    describe "excluded models" do
      excluded_models = [Division, Draft, Fan]

      before(:all) do
        RailsAdmin::Config.excluded_models = excluded_models
      end

      after(:all) do
        RailsAdmin::Config.excluded_models = []
        RailsAdmin::AbstractModel.instance_variable_get("@models").clear
        RailsAdmin::Config.reset
      end

      it "should be hidden from navigation" do
        # Make query in team's edit view to make sure loading
        # the related division model config will not mess the navigation
        get rails_admin_new_path(:model_name => "team")
        excluded_models.each do |model|
          response.should have_tag("#nav") do |navigation|
            navigation.should_not have_tag("li a", :content => model.to_s)
          end
        end
      end

      it "should raise NotFound for the list view" do
        get rails_admin_list_path(:model_name => "fan")
        response.status.should equal(404)
      end

      it "should raise NotFound for the create view" do
        get rails_admin_new_path(:model_name => "fan")
        response.status.should equal(404)
      end

      it "should be hidden from other models relations in the edit view" do
        get rails_admin_new_path(:model_name => "team")
        response.should_not have_tag("#team_division_id")
        response.should_not have_tag("input#team_fans")
      end

    end

    describe "navigation" do

      describe "number of visible tabs" do
        after(:each) do
          RailsAdmin.config do |config|
            config.navigation.max_visible_tabs = 5
          end
        end

        it "should be editable" do
          RailsAdmin.config do |config|
            config.navigation.max_visible_tabs = 2
          end
          get rails_admin_dashboard_path
          response.should have_tag("#nav > li") do |elements|
            elements.should have_at_most(4).items
          end
        end
      end

      describe "label for a model" do

        after(:each) do
          RailsAdmin::Config.reset Fan
        end

        it "should be visible and sane by default" do
          # Reset
          RailsAdmin::Config.reset Fan

          get rails_admin_dashboard_path
          response.should have_tag("#nav") do |navigation|
            navigation.should have_tag("li a", :content => "Fan")
          end
        end

        it "should be editable" do
          RailsAdmin.config Fan do
            label "Fan test 1"
          end
          get rails_admin_dashboard_path
          response.should have_tag("#nav") do |navigation|
            navigation.should have_tag("li a", :content => "Fan test 1")
          end
        end

        it "should be editable via shortcut" do
          RailsAdmin.config Fan do
            label_for_navigation "Fan test 2"
          end
          get rails_admin_dashboard_path
          response.should have_tag("#nav") do |navigation|
            navigation.should have_tag("li a", :content => "Fan test 2")
          end
        end

        it "should be editable via navigation configuration" do
          RailsAdmin.config Fan do
            navigation do
              label "Fan test 3"
            end
          end
          get rails_admin_dashboard_path
          response.should have_tag("#nav") do |navigation|
            navigation.should have_tag("li a", :content => "Fan test 3")
          end
        end

        it "should be editable with a block via navigation configuration" do
          RailsAdmin.config Fan do
            navigation do
              label do
                "#{label} test 4"
              end
            end
          end
          get rails_admin_dashboard_path
          response.should have_tag("#nav") do |navigation|
            navigation.should have_tag("li a", :content => "Fan test 4")
          end
        end

        it "should be hideable" do
          RailsAdmin.config Fan do
            hide
          end
          get rails_admin_dashboard_path
          response.should have_tag("#nav") do |navigation|
            navigation.should_not have_tag("li a", :content => "Fan")
          end
        end

        it "should be hideable via shortcut" do
          RailsAdmin.config Fan do
            hide_in_navigation
          end
          get rails_admin_dashboard_path
          response.should have_tag("#nav") do |navigation|
            navigation.should_not have_tag("li a", :content => "Fan")
          end
        end

        it "should be hideable via navigation configuration" do
          RailsAdmin.config Fan do
            navigation do
              hide
            end
          end
          get rails_admin_dashboard_path
          response.should have_tag("#nav") do |navigation|
            navigation.should_not have_tag("li a", :content => "Fan")
          end
        end

        it "should be hideable with a block via navigation configuration" do
          RailsAdmin.config Fan do
            navigation do
              show do
                false
              end
            end
          end
          get rails_admin_dashboard_path
          response.should have_tag("#nav") do |navigation|
            navigation.should_not have_tag("li a", :content => "Fan")
          end
        end
      end
    end

    describe "edit" do

      describe "field groupings" do

        it "should be hideable" do
          RailsAdmin.config Team do
            edit do
              group :default do
                label "Hidden group"
                hide
              end
            end
          end
          get rails_admin_new_path(:model_name => "team")
          # Should not have the group header
          response.should_not have_tag("h2", :content => "Hidden Group")
          # Should not have any of the group's fields either
          response.should_not have_tag("select#team_league_id")
          response.should_not have_tag("select#team_division_id")
          response.should_not have_tag("input#team_name")
          response.should_not have_tag("input#team_logo_url")
          response.should_not have_tag("input#team_manager")
          response.should_not have_tag("input#team_ballpark")
          response.should_not have_tag("input#team_mascot")
          response.should_not have_tag("input#team_founded")
          response.should_not have_tag("input#team_wins")
          response.should_not have_tag("input#team_losses")
          response.should_not have_tag("input#team_win_percentage")
          response.should_not have_tag("input#team_revenue")

          # Reset
          RailsAdmin::Config.reset Team
        end

        it "should be renameable" do
          RailsAdmin.config Team do
            edit do
              group :default do
                label "Renamed group"
              end
            end
          end
          get rails_admin_new_path(:model_name => "team")
          response.should have_tag("h2", :content => "Renamed group")

          # Reset
          RailsAdmin::Config.reset Team
        end
      end

      describe "items' fields" do

        it "should show all by default" do
          get rails_admin_new_path(:model_name => "team")
          response.should have_tag("select#team_league_id")
          response.should have_tag("select#team_division_id")
          response.should have_tag("input#team_name")
          response.should have_tag("input#team_logo_url")
          response.should have_tag("input#team_manager")
          response.should have_tag("input#team_ballpark")
          response.should have_tag("input#team_mascot")
          response.should have_tag("input#team_founded")
          response.should have_tag("input#team_wins")
          response.should have_tag("input#team_losses")
          response.should have_tag("input#team_win_percentage")
          response.should have_tag("input#team_revenue")
          response.should have_tag("input#team_players")
          response.should have_tag("input#team_fans")
        end

        it "should appear in order defined" do
          RailsAdmin.config Team do
            edit do
              field :manager
              field :division_id
              field :name
            end
          end
          get rails_admin_new_path(:model_name => "team")
          response.should have_tag(".field") do |elements|
            elements[0].should have_tag("#team_manager")
            elements[1].should have_tag("#team_division_id")
            elements[2].should have_tag("#team_name")
          end

          # Reset
          RailsAdmin::Config.reset Team
        end

        it "should only show the defined fields if some fields are defined" do
          RailsAdmin.config Team do
            edit do
              field :league_id
              field :division_id
              field :name
            end
          end
          get rails_admin_new_path(:model_name => "team")
          response.should have_tag(".field") do |elements|
            elements[0].should have_tag("#team_league_id")
            elements[1].should have_tag("#team_division_id")
            elements[2].should have_tag("#team_name")
            elements.length.should == 3
          end

          # Reset
          RailsAdmin::Config.reset Team
        end

        it "should be renameable" do
          RailsAdmin.config Team do
            edit do
              field :manager do
                label "Renamed field"
              end
              field :division_id
              field :name
            end
          end
          get rails_admin_new_path(:model_name => "team")
          response.should have_tag(".field") do |elements|
            elements[0].should have_tag("label", :content => "Renamed field")
            elements[1].should have_tag("label", :content => "Division")
            elements[2].should have_tag("label", :content => "Name")
          end

          # Reset
          RailsAdmin::Config.reset Team
        end

        it "should be renameable by type" do
          RailsAdmin.config Team do
            edit do
              fields_of_type :string do
                label { "#{label} (STRING)" }
              end
            end
          end
          get rails_admin_new_path(:model_name => "team")
          response.should have_tag(".field") do |elements|
            elements.should have_tag("label", :content => "League")
            elements.should have_tag("label", :content => "Division")
            elements.should have_tag("label", :content => "Name (STRING)")
            elements.should have_tag("label", :content => "Logo url (STRING)")
            elements.should have_tag("label", :content => "Manager (STRING)")
            elements.should have_tag("label", :content => "Ballpark (STRING)")
            elements.should have_tag("label", :content => "Mascot (STRING)")
            elements.should have_tag("label", :content => "Founded")
            elements.should have_tag("label", :content => "Wins")
            elements.should have_tag("label", :content => "Losses")
            elements.should have_tag("label", :content => "Win percentage")
            elements.should have_tag("label", :content => "Revenue")
            elements.should have_tag("label", :content => "Players")
            elements.should have_tag("label", :content => "Fans")
          end

          # Reset
          RailsAdmin::Config.reset Team
        end

        it "should be globally renameable by type" do
          RailsAdmin::Config.model do
            edit do
              fields_of_type :string do
                label { "#{label} (STRING)" }
              end
            end
          end
          get rails_admin_new_path(:model_name => "team")
          response.should have_tag(".field") do |elements|
            elements.should have_tag("label", :content => "League")
            elements.should have_tag("label", :content => "Division")
            elements.should have_tag("label", :content => "Name (STRING)")
            elements.should have_tag("label", :content => "Logo url (STRING)")
            elements.should have_tag("label", :content => "Manager (STRING)")
            elements.should have_tag("label", :content => "Ballpark (STRING)")
            elements.should have_tag("label", :content => "Mascot (STRING)")
            elements.should have_tag("label", :content => "Founded")
            elements.should have_tag("label", :content => "Wins")
            elements.should have_tag("label", :content => "Losses")
            elements.should have_tag("label", :content => "Win percentage")
            elements.should have_tag("label", :content => "Revenue")
            elements.should have_tag("label", :content => "Players")
            elements.should have_tag("label", :content => "Fans")
          end

          # Reset
          RailsAdmin::Config.reset
        end

        it "should be hideable" do
          RailsAdmin.config Team do
            edit do
              field :manager do
                hide
              end
              field :division_id
              field :name
            end
          end
          get rails_admin_new_path(:model_name => "team")
          response.should have_tag(".field") do |elements|
            elements[0].should have_tag("#team_division_id")
            elements[1].should have_tag("#team_name")
          end

          # Reset
          RailsAdmin::Config.reset Team
        end

        it "should be hideable by type" do
          RailsAdmin.config Team do
            edit do
              fields_of_type :string do
                hide
              end
            end
          end
          get rails_admin_new_path(:model_name => "team")
          response.should have_tag(".field") do |elements|
            elements.should have_tag("label", :content => "League")
            elements.should have_tag("label", :content => "Division")
            elements.should_not have_tag("label", :content => "Name")
            elements.should_not have_tag("label", :content => "Logo url")
            elements.should_not have_tag("label", :content => "Manager")
            elements.should_not have_tag("label", :content => "Ballpark")
            elements.should_not have_tag("label", :content => "Mascot")
            elements.should have_tag("label", :content => "Founded")
            elements.should have_tag("label", :content => "Wins")
            elements.should have_tag("label", :content => "Losses")
            elements.should have_tag("label", :content => "Win percentage")
            elements.should have_tag("label", :content => "Revenue")
            elements.should have_tag("label", :content => "Players")
            elements.should have_tag("label", :content => "Fans")
          end

          # Reset
          RailsAdmin::Config.reset Team
        end

        it "should be globally hideable by type" do
          RailsAdmin::Config.model do
            edit do
              fields_of_type :string do
                hide
              end
            end
          end
          get rails_admin_new_path(:model_name => "team")
          response.should have_tag(".field") do |elements|
            elements.should have_tag("label", :content => "League")
            elements.should have_tag("label", :content => "Division")
            elements.should_not have_tag("label", :content => "Name")
            elements.should_not have_tag("label", :content => "Logo url")
            elements.should_not have_tag("label", :content => "Manager")
            elements.should_not have_tag("label", :content => "Ballpark")
            elements.should_not have_tag("label", :content => "Mascot")
            elements.should have_tag("label", :content => "Founded")
            elements.should have_tag("label", :content => "Wins")
            elements.should have_tag("label", :content => "Losses")
            elements.should have_tag("label", :content => "Win percentage")
            elements.should have_tag("label", :content => "Revenue")
            elements.should have_tag("label", :content => "Players")
            elements.should have_tag("label", :content => "Fans")
          end

          # Reset
          RailsAdmin::Config.reset
        end

        it "should have option to customize the help text" do
          RailsAdmin.config Team do
            edit do
              field :manager do
                help "#{help} Additional help text for manager field."
              end
              field :division_id
              field :name
            end
          end
          get rails_admin_new_path(:model_name => "team")
          response.should have_tag(".field") do |elements|
            elements[0].should have_tag("p.help", :content => "Required 100 characters or fewer. Additional help text for manager field.")
            elements[1].should have_tag("p.help", :content => "Required")
            elements[2].should have_tag("p.help", :content => "Optional 50 characters or fewer.")
          end

          # Reset
          RailsAdmin::Config.reset Team
        end

        it "should have option to override required status" do
          RailsAdmin.config Team do
            edit do
              field :manager do
                optional true
              end
              field :division_id do
                optional true
              end
              field :name do
                required true
              end
            end
          end
          get rails_admin_new_path(:model_name => "team")
          response.should have_tag(".field") do |elements|
            elements[0].should have_tag("p.help", :content => "Optional 100 characters or fewer.")
            elements[1].should have_tag("p.help", :content => "Optional")
            elements[2].should have_tag("p.help", :content => "Required 50 characters or fewer.")
          end

          # Reset
          RailsAdmin::Config.reset Team
        end
      end

      describe "fields which are nullable and have AR validations" do
        it "should be required" do
          # draft.notes is nullable and has no validation
          field = RailsAdmin::config("Draft").edit.fields.find{|f| f.name == :notes}
          field.properties[:nullable?].should be true
          field.required?.should be false

          # draft.date is nullable in the schema but has an AR
          # validates_presence_of validation that makes it required
          field = RailsAdmin::config("Draft").edit.fields.find{|f| f.name == :date}
          field.properties[:nullable?].should be true
          field.required?.should be true

          # draft.round is nullable in the schema but has an AR
          # validates_numericality_of validation that makes it required
          field = RailsAdmin::config("Draft").edit.fields.find{|f| f.name == :round}
          field.properties[:nullable?].should be true
          field.required?.should be true

          # team.revenue is nullable in the schema but has an AR
          # validates_numericality_of validation that allows nil
          field = RailsAdmin::config("Team").edit.fields.find{|f| f.name == :revenue}
          field.properties[:nullable?].should be true
          field.required?.should be false
        end
      end

    end
  end
end