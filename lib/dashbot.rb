require "dashbot/version"

module Dashbot

	require 'json'
	require 'rest-client'

	class DashbotSDK  
	  
	  def initialize(apiKey, session)  
	  
	  	@apiKey = ''  
	  	@session = nil
	  	@debug = false
	  	@urlRoot = 'https://tracker.dashbot.io/track'
	  	@platform = 'alexa'
	  	@source = 'gem'
	  	@version = Dashbot::VERSION
	  	    
	    if session == nil or apiKey == nil or apiKey.length == 0
	      puts "ERROR: invalid session or apiKey passed"
	      return
	    end

	    if @session and @session['sessionId'] == session['sessionId']
	      puts "Session Exists: " + @session['sessionId']
	      return self
	    end

	    # Instance variables  
	    @apiKey = apiKey  
	    @session = session 

	  end  
	  
	  def regenerateEvent(intent,slots)
        request = {
            type:'IntentRequest',
            intent: {
                name:intent,
                slots:slots
            }
        }
        event = {
            session: @session,
            request:request,
            context:{
                System:{
                    application:@session['application'],
                    user:@session['user']
                }
            }
        }
        return event
       end
        
    def generateResponse(speechText)
        if speechText[0,7]=='<speak>'
            return {
                response:{
                    outputSpeech:{
                        type:'SSML',
                        ssml: speechText
                    }
                }       
            }
        else
            return {
                response:{
                    outputSpeech:{
                        type:'Plaintext',
                        text:speechText
                    }
                }
            }
        end
	  end
	  
	  def track(intent_name, intent_request, response)  

	    if(!intent_name)
	        puts "ERROR: intent_name cannot be null"
	        return
	    end

	    if @session == nil
	        puts "ERROR: Dashbot SDK has not been initialized. Initalize() method need to have been invoked before tracking"
	        return
	    end
	          
		event = regenerateEvent(intent_name,intent_request['intent']['slots'])

	    begin
	    	response = JSON.parse(response)
	    rescue
		    response = response
		end

	    #set data
	    if response.is_a? String
	        speechText = response

	    elsif response and response.key?('response') and response['response'].key?('outputSpeech')

	        speechObj = response['response']['outputSpeech']

	        if speechObj.key?('type')
	            
	            if speechObj['type'] == 'SSML'
	                speechText = response['response']['outputSpeech']['ssml']

	            elsif speechObj['type'] == 'PlainText'
	                speechText = response['response']['outputSpeech']['text']

	            else
	                puts "ERROR: passed a response object with an unknown Type"
	            end

	        else
	            puts "ERROR: passed a response object thats not an Alexa response"
	        end

	    else
	        speechText = nil
	    end
	    
        responseGenerated = generateResponse(speechText)
        logIncoming(event)
        logOutgoing(event,responseGenerated)
	  end  

    def makeRequest(sURL,payload)
        begin
	      response = RestClient::Request.execute(method: :post, 
	                                  url: sURL,
	                                  payload: payload.to_json, 
	                                  headers: {content_type: :json},
	                                  timeout: 1)
	      
	    rescue Exception => e
	      puts "Exception occurred: msg = " + e.message
	      puts e.response.body
	      puts e.backtrace.inspect
		end
     end
     
    def logIncoming(event)
        url = @urlRoot + '?apiKey=' + @apiKey + '&type=incoming&platform='+ @platform + '&v=' + @version + '-' + @source
        
        if @debug
            puts 'Dashbot Incoming:'+url
            puts event
        end
        data={
            event:event,
            }
                        
        makeRequest(url,data)
    end
            
    def logOutgoing(event,response)
        url = @urlRoot + '?apiKey=' + @apiKey + '&type=outgoing&platform='+ @platform + '&v=' + @version + '-' + @source
        
        if @debug
            puts 'Dashbot Outgoing:'+url
            puts event
        end
        data={
            event:event,
            response:response            
        }
        
        makeRequest(url,data)     
        
    end  

	end 
 end

