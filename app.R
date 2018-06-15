library(shiny)
library(dplyr)
library(DT)
library(ggplot2)
library(tm)
library(wordcloud)
library(memoise)

Sys.setlocale('LC_ALL','C')
story <- readRDS(file ="story.Rda")
matrix <- readRDS(file ="matrix.Rda")
all_trends <- c("Radio", "YouTube", "Shuffle", "Playlist", "Vinyl", "ipod", "Spotify", "Radio")
n_total <- nrow(story)
all_methods <- sort(unique(story$method))
all_years <- sort(unique(story$year))
all_topics <- sort(unique(story$top))
all_sent_name <- sort(unique(story$sent_name))

# Define UI for application that plots features of movies
ui <- fluidPage(
  h3(img(src='http://harkive.org/wp-content/uploads/2015/07/CLMIv-GWwAQbeQS-300x300.png', height = 25, width = 25), 'The Harkive Project: 2013-2017 - Data Anaylsis Explorer, v1.0'),
  sidebarLayout(
    
    # Inputs
    sidebarPanel(
      
      selectInput(inputId = "year",
                  label = "Select Year:",
                  choices = all_years,
                  selected = all_years,
                  multiple = T),
      
      selectInput(inputId = "method",
                  label = "Select Method:",
                  choices = all_methods,
                  selected = c("Twitter", "Facebook", "Tumblr", "Instagram", "Platform"),
                  multiple = T),
      
      selectInput(inputId = "z", 
                  label = "Color Barplot by:",
                  choices = c("Topic" = "top", "Method" = "method", "Sentiment" = "sent_name"),
                  selected = "top"),
      
      sliderInput(inputId = "words", 
                  label = "Select maximum words in a story:",
                  min = min(story$wordsinstory), max = max(story$wordsinstory),
                  value = 150, step = 1),
      
      selectInput(inputId = "topic",
                  label = "Select Topic:",
                  choices = c("Emotion" = "Emotion", "Radio" = "Radio", 
                              "Streaming" = "Streaming", "Physical Formats" = "Physical",
                              "Time & Place" = "Time & Place", "Listening + Context" = "Context", "Choice" = "Choice", "The Harkive Project" 
                              = "Harkive"),
                  selected = all_topics,
                  multiple = T),
      
      selectInput(inputId = "sent_name",
                  label = "Select Sentiment:",
                  choices = c("Positive" = "Pos", "Neutral" = "Neu", 
                              "Negative" = "Neg"),
                  selected = all_sent_name,
                  multiple = T),
      
      sliderInput("wordfreq",
                  "Set Minimum Word Frequency plot:",
                  min = 75,  max = 450, value = 200, step = 1),
      
      selectInput(inputId = "trend_name",
                  label = "Add/Remove word Trends plot:",
                  choices = all_trends,
                  selected = all_trends,
                  multiple = T),
      hr(),
      #p(), img(src='http://harkive.org/wp-content/uploads/2015/07/CLMIv-GWwAQbeQS-300x300.png', height = 50, width = 50), img(src='bcu.jpeg', height = 50, width = 50),  
      p(), h6("This app was developed for", a(href="http://www.harkive.org", "The Harkive Project", target="_blank"), 
              "by", a(href="https://www.bcu.ac.uk/media/research/research-staff/craig-hamilton", "Craig Hamilton,", target="_blank"), 
              "a Research Fellow 
              in the", a(href="http://www.bcmcr.org", "Birmingham Centre of Media and Cultural Studies Research", target="_blank"), 
              "at", a(href="https://www.bcu.ac.uk", "Birmingham City University.", target="_blank"), "It is powered by", 
              a(href="https://shiny.rstudio.com", "Shiny, from R Studio.", target="_blank"), "All enquiries about this app should 
              be emailed to", a(href="mailto:craig.hamilton@bcu.ac.uk?subject=Harkive Shiny App question", "Craig Hamilton."))
      ),
    
    # Output: Show data table
    mainPanel(
      tabsetPanel(type = "tabs",
                  #tabPanel("Overview", plotOutput(outputId = "scatterplot")),
                  tabPanel("Overview", p(), h4("About this App"), "This Shiny application displays data gathered by", 
                           tags$b("The Harkive Project"), "between 2013 and 2017", 
                           p(), "Harkive is an annual, online music research project that gathers stories from people 
                           around the world about how, where and why they listen to music during the course of a single day. Since launching in 2013, the project 
                           has gathered over 10,000 stories and returns for a 6th time on", tags$b("Tuesday 17th July 2018. "), 
                           "For more information about Harkive, and to find out how you can tell your story, visit", 
                           a(href="http://www.harkive.org", "www.harkive.org", target="_blank"), p(),
                           "This app will enable you to explore over 8,000 of the stories gathered so far. You can subset the data according to a 
                           number of parameters, see visualisations based on the results of computational analyses, and also read the stories. You can also 
                           use the app to tell your story to Harkive in 2018, over on the", tags$b("Tell Your Story"),  "tab",
                           h4("How to use this Shiny App"),
                           p(), "1) Use the", tags$b("control panel on the left hand side"), "to subset the data based on combinations 
                           of the years in which the stories were gathered ", tags$i("(Select Year)"), ", the various methods through which the stories were told", 
                           tags$i("(Select Method)"), ", on the results of computational analyses ", tags$i("(Select Topic; Select Sentiment)"), ", or on the 
                           length of stories", tags$i("(Maximum Words)"), p(),"You can try that out here on this page first. The current configuration of 
                           selections on the control panel returns a subset of the database. Change some of the parameters by adding and deleting options, 
                           and you will see the details below change", p(), textOutput(outputId = "counting"),tags$head(tags$style("#counting{color: red;
                                                                                                                                   font-size: 15px;
                                                                                                                                   font-style: italic;
                                                                                                                                   }"
)
                  ), p(), "2) You can use the", tags$b("tabs across the top of the main panel"), "to read the stories returned by your selection, or 
see visualisations based on that selection. When you are on the various tabs, you can continue to use the", tags$b("control panel"), 
"to alter your selection and the visualisations will change accordingly. You can also use the", tags$b("Word Frequency"), "slider to 
change what is displayed on the Word Frequencies tab. On each visualisation tab you will see information based on your 
current selection", p(), "If you are interested in replicating or bulding on this work, go to the ", tags$b("Recources"), "tab to 
get sample data, code, and instructions, along with links to external resources"),
tabPanel("Barplot",p(), "This barplot provides a visual overview of your current selection, organised by year. You can
         use the", tags$b("Colour Barplot by"), "option to fill the plot by",tags$i("Topic, Method"),"and",
         tags$i("Sentiment."), "Adding and removing elements from the", tags$b("Year, Method, Topic"),
         "or", tags$b("Sentiment"), "options will subset the database further, as will the", tags$b("Select maximum words"),
         "slider.", p(), plotOutput(outputId = "barplot")),
tabPanel("Read the Stories",p(), "On this tab you can read the Harkive stories returned by your selection. 
         You can continue to subset the database here using the options on the left, and within the dataframe you can
         search for keywords within that selection.", p() ,tags$b("NB"), "The keyword search relates only to this tab
         and will not alter your overall selection", p(), hr(),  DT::dataTableOutput(outputId = "storytable")),

##FIX THIS####FIX THIS####FIX THIS####FIX THIS####FIX THIS####FIX THIS####FIX THIS##

#tabPanel("Topics & Sentiment", plotOutput(outputId = "sent_topic")),

##FIX THIS####FIX THIS####FIX THIS####FIX THIS####FIX THIS####FIX THIS####FIX THIS##

tabPanel("Sentiment Analysis", p(), "Sentiment Analysis algorithms search documents for the appearance of 
         certain words, producing an overall value that marks a document as either exhibiting a positive, 
         negative, or neutral sentiment.", p(), "Four different libraries have been used. The", tags$i("nrc"), "component returns separate scores for 
         words its developers consider to resemble themes of", tags$i("anger, anticipation, disgust, fear, joy, sadness, surprise"), "and", 
         tags$i("trust."), "Based on your selection, the total number of stories in each category is displayed below.", 
         p(), plotOutput(outputId = "sentplot")),

#FIX THIS --- #FIX THIS --- #FIX THIS --- #FIX THIS --- #FIX THIS --- #FIX THIS --- 

#                  tabPanel("Wordcloud", p() ,"This wordcloud shows words that appear most frequently in the Harkive stories you have selected, 
# with the most frequently occuring words appearing larger and darker than less frequently occuring words. Use the", tags$b("Word Frequency"), 
# "slider in the control panel to lower the threshold and see more words. The default setting is 150 words, the minimum available is 75.", 
# p(), "You can continue to subset the database according to", tags$b("Years, Method, Word Count, Topic"), "and", tags$b("Sentiment"), "but 
# may need to alter the", tags$b("Word Frequency"), "slider to a lower threshold the more you subset the database. The lowest number of words 
# available in this visualisation is 75", plotOutput(outputId = "wordcloudplot"), p(), tags$b("NB:"), "Words here have been stemmed to their 
# roots to avoid duplication. For example, instances of the words", tags$i("Listen, Listening, Listener, Listened"), "appear together as", 
#tags$i("listen."), "You may also notice that familiar brand names, such as", tags$i("Spotify"), "look slightly different", tags$i("(spotifi)"), 
# "due to the word stemming process"),

#FIX THIS --- #FIX THIS --- #FIX THIS --- #FIX THIS --- #FIX THIS --- #FIX THIS --- 

tabPanel("Word Frequencies", p() ,"This chart shows words that appear most frequently in the Harkive stories you have selected. 
         Use the", tags$b("Word Frequency"), "slider in the control panel to set the lowest threshold. The default setting is 150 words.", p(), "You can 
         continue to subset the database according to", tags$b("Years, Method, Word Count, Topic"), "and", tags$b("Sentiment"), 
         "but may need to alter the", tags$b("Word Frequency"), "slider to a lower threshold the more you subset the database. 
         The lowest number of words available in this visualisation is 75", p(), plotOutput(outputId = "wordfrequency"), p(), 
         tags$b("NB:"), "Words here have been stemmed to their roots to avoid duplication. For example, instances of the words", 
         tags$i("Listen, Listening, Listener, Listened"), "appear together as", tags$i("listen."), "You may also notice that 
         familiar brand names, such as", tags$i("Spotify"), "look slightly different", tags$i("(spotifi)"), "due to the word 
         stemming process"),
tabPanel("Trends", p(), "This chart in intended to give some indication of trends over the life of the project so far. The percentage of stories
         each year containing key words related to listening is displayed. Subsetting the database according to combinations of", tags$b("year, method, 
                                                                                                                                         sentiment, topic"),
         "or", tags$b("word count"), "will result in a change in this visualisation",p(), "You can add or remove words from this visualisation
         by using the", tags$b("Add/Remove Trend Words"), "option in the control panel", tags$b("NB:"), "Adding or removing words in this
         plot will not alter your overall selection", plotOutput(outputId = "trends")), 
tabPanel("Tell your story - 2018", p(), "Harkive 2018 will take place on Tuesday 17th July. You can find out more about the project
         by visiting the website,", a(href="http://www.harkive.org", "www.harkive.org", target="_blank"), "but you can also find that same information
         here in this app. Under", tags$b("Resources"), "you will find addtional tabs on", tags$b("How to 
                                                                                                  Contribute to Harkvie 
                                                                                                  2018"),
         "and the", tags$b("Research Ethics"), "underpinning the project" ,p(), "One simple way you can get involved on 
         17th July is to complete the form below. Enter your name, location 
         and your Harkive story and click submit. There is no word limit, and you can submit as many entries as you like.", p(), htmlOutput("submit")),

#FIX THIS - - - - - #FIX THIS - - - - - #FIX THIS - - - - -#FIX THIS - - - - -#FIX THIS - - - - -

#tabPanel("Music Listening Survey - 2018", p(), "Beyond telling your stories to Harkive on Tuesday 17th July 2018, you can also get
#         involved by completing the 2018 Music Listening Survey. Your responses to the questions in this survey will help provide
#         some additional context when the analysis of the 2018 stories begins. The survey takes around 5-10 minutes to complete and is
#         posted below. The survey begins with a page of information regarding your Informed Consent, which you are encouraged to read before
#         proceeding.", p(), "Hopefully you'll enjoy answering some questions about your music listening!", p(), htmlOutput("survey")),

#FIX THIS - - - - -#FIX THIS - - - - -#FIX THIS - - - - -#FIX THIS - - - - -#FIX THIS - - - - -

navbarMenu("Resources",
           tabPanel("Research Context", p(), h3(img(src='http://harkive.org/wp-content/uploads/2015/07/CLMIv-GWwAQbeQS-300x300.png', height = 75, width = 75)), p(),
                    h3("Research Context"), p(), tags$b("The Harkive Project"), "started in 2013, developed as 
                    the final piece of my MA Music Industries studies at Birmingham City University. It subsequently became the focus of my PhD research, 
                    which started in October 2014. This work was funded by the", a(href="http://www.midlands3cities.ac.uk","AHRC Midlands3Cities Doctoral Training 
                                                                                   Partnership", target="_blank"), "and again took place at BCU. It was jointly supervised by Profs",
                    a(href="http://www.bcu.ac.uk/research/our-people/f-i/nick-gebhardt", 
                      "Nick Gebhardt", target="_blank"), "and", 
                    a(href="https://www.bcu.ac.uk/media/research/research-staff/tim-wall", 
                      "Tim Wall.", target="_blank"), p(), "I was awarded my doctorate in January 2018 and shortly 
                    afterwards started as a Research Fellow in the Birmingham Centre for Media and Cutural Research
                    ", a(href="http://www.bcmcr.org", "(BCMCR)", target="_blank"), "at BCU. The 
                    continued development of The Harkive Project - including annual iterations of data collection part of the project - 
                    is the primary focus of my research. This Shiny application forms part of that ongoing work.", p(),
                    "In my research I am interested in exploring the relationships between digital, 
                    data and internet technologies, and everyday acts of what Keith Negus (1997: 8) calls music reception -", 
                    tags$i("'how people receive, interpret and use music as a cultural form while 
                           engaging in specific social activities.'"), "The stories gathered by The Harkive Project, and 
                    the manner in which I have chosen to analyse them, provide the means for that investigation. Below I have
                    posted an excerpt from the opening chapter of my PhD thesis, which I hope will go some way to explain
                    the rationale for the apporach I have taken.", p(), "I hope you enjoy reading it, and I hope you 
                    will consider joining in with The Harkive Project 2018 on Tuesday 17th July.", p(), "Kind regards,", 
                    p(), "Craig Hamilton", p(), "Birmingham, UK. June 2018.", p(),
                    h4("************", align = "center"),
                    "Over the last two decades digital, data and Internet technologies have emerged as an important and 
                    influential factor in how popular music is produced, distributed and consumed. These technologies, 
                    allied to practices of data collection and computational analysis, now play a significant role both in how audiences engage with music, 
                    and how those audiences are understood. A key point here is that popular music audiences are now highly individualised, and 
                    defined according to a growing number of new categorical variables. At the same time they are also understood 
                    through the agglomeration of data points in a manner that recalls earlier conceptions of mass audiences. 
                    These intriguing new conditions invite us to revisit questions that have concerned popular music scholars 
                    for over 80 years, including issues of choice, agency, ownership, how audiences are constructed and understood, 
                    and how people derive meaning from popular music.", p(),
                    "However, the systems of data collection and analysis that facilitate 
                    this are technologically complex, subject to rapid change, and often hidden behind commercial and legal firewalls. This makes the study of 
                    them particularly difficult. At the same time, the use of digital and data technologies by many people 
                    during the course of their everyday lives is providing scholars with new opportunities and methods for 
                    undertaking research in the humanities. This in turn is leading to questions about the role of the 
                    researcher in popular music studies, and how the discipline may take into account the new technologies 
                    and practices that have so changed the field. These are the inter-related issues my work addresses.", p(),
                    "At the heart of my work is a piece of research on the music reception practices of contemporary music 
                    listeners, but what I then go on to do extends far beyond answering a single question, and into issues of 
                    research methodology and even the conceptualisation of music culture. My work, though, starts with a 
                    simple research question: What can an analysis of the data generated by The Harkive Project reveal 
                    about the music reception practices of its respondents? ", p(),
                    "To answer this question, I have developed an experimental, innovative approach that conceives of Harkive 
                    as a space in which people can reflect upon their engagement with music, whilst simultaneously acting as a 
                    place that is able to replicate many of the commercial practices related to data collection and processing. 
                    Through this space, I critically engage with the growing role of data and digital technologies associated 
                    with music consumption, whilst exploring the use of computational techniques in popular music studies 
                    research. The specific means by which this approach enables me to answer my research question can be 
                    understood by considering the processes through which Harkive gathers text-based descriptions of music 
                    reception activities, the 'metadata' that accompanies those texts, the qualitative data gathered from a 
                    music listening survey, and the additional data produced through the use of computational analytical 
                    processing, including unsupervised machine learning algorithms. This means that the data about music 
                    reception activities available to me can be understood and analysed in a number of different ways, 
                    ranging from close readings of texts more usually associated with humanities research, through to the 
                    clustering, visualisation and analysis of abstractions generated through computational/algorithmic 
                    processing that renders the original texts as data. The method also allows for analyses that combine 
                    these approaches. Together they enable me to provide a number of answers to my central research question.",
                    p(),
                    "I show that Harkive respondents describe intriguing new cultural practices associated with music reception 
                    that can be understood as combinations of both new (digital) and existing (pre-digital) practices. For example, 
                    many of my respondents describe their use of digital interfaces in terms of vinyl record ownership, collection 
                    and use. Respondents also describe engaging in both 'new' and 'old' modes of engagement separately, and switch 
                    between all available modes with considerable dexterity.  A number of the new conditions of engagement 
                    I have explored, specifically connectivity, digital interfaces, data-derived abstractions, and mobility, 
                    are also in evidence in respondent stories.  This relates to the manner in which people switch between 
                    streaming and other online services and how they understand that process. There is very little evidence 
                    of Harkive respondents explicitly voicing similar concerns to those raised by a number of theorists regarding 
                    the potential impacts of the data collection and analysis - something I explore in my opening chapters. 
                    However, respondent narratives do contain acknowledgement of the role and function of these technologies, 
                    and it is in that context that interesting new questions arise.", p(),
                    "The manner in which Harkive respondents also describe entering into a form of communication and/or 
                    relationship with data-derived abstractions (of their activities, of their selves, of available catalogues) 
                    indicates the importance of undertaking further studies in this area.  Of particular interest are automated 
                    recommender systems, the manner in which digital interfaces foreground (or not) content to audiences, 
                    and the new ways in which audiences are conceived of and organised, and how this relates to questions of 
                    choice, agency and identity. Relatedly, concerns over the potential consequences of data-collection and 
                    analysis that were not present in respondent narratives but were evident in the survey-gathering element 
                    of the process, suggests that further work in this area may also be fruitful.", p(),
                    "In reflecting upon the issues and questions that have informed the development of my method, I consider 
                    how as a researcher I initially lacked the technical skills required to collect, prepare and analyse data 
                    in the manner I had identified as being of potential use. This project, then, became as much about how to 
                    conceive of new methods for studying the reception of music in the digital age. The approach I took drew 
                    on similar methods to those highlighted by the issues of debate above and are linked to both commercial 
                    practices in popular music, and to methods associated with the 'computational turn' (Berry, 2011; Hall, 2013) 
                    in humanities research. Data collection processes and computational techniques are shown, for instance, to be 
                    inherently reductive, which often prevents them from capturing and accurately reflecting complex cultural 
                    practices. In particular, text-based, qualitative data is a difficult form of data to process using computational 
                    methods and can lead to results that are problematic.", p(),
                    "I also consider the extent to which the different modes of analysis afforded by my modular method have 
                    enabled me to arrive at different forms of insight that may not have been possible through methods usually 
                    associated with the humanities. Reflecting on these potential benefits and problems, I want to suggest that it 
                    is possible for popular music scholars to gain a better understanding of the new conditions of popular music's 
                    production, distribution and consumption through a combination of practical and critical engagement with processes 
                    of data collection and analysis. I suggest that the work I have undertaken in this project provides a springboard 
                    for that future work, and in particular for the creation of new tools, platforms, and research projects that may 
                    enable both consumers and scholars to develop useful and productive epistemic responses to the role of digital, 
                    data and Internet technologies.", p(),
                    "Ultimately, I argue that a greater practical understanding and critical engagement with digital, data and 
                    Internet technologies is possible, both for music consumers and popular music scholars, and I demonstrate 
                    how my work represents a significant step towards that.", p()
                    ),
           tabPanel("Research Ethics and Informed Consent", p(), h3(img(src='http://harkive.org/wp-content/uploads/2015/07/CLMIv-GWwAQbeQS-300x300.png', height = 75, width = 75)),
                    h3("Research Ethics and Informed Consent"),
                    p(), h4("INFORMATION"),
                    "Harkive is an annual, online research project that over the course of a single day aims to gather stories 
                    and other data from people about the detail of their music listening. The 2018 instance of The Harkive Project will take place on 
                    Tuesday 17th July.", p(), 
                    "Harkive is part of research being undertaken by Craig Hamilton, a fellow at Birmingham City University. 
                    The methods of data collection, storage and analysis used by the project have been designed in accordance 
                    with the", 
                    a(href="https://www.bcu.ac.uk/cmsproxyimage?path=/_media/docs/bcu-%20research_ethical_framework.23.11.10.pdf",
                      "ethical guidelines for research activity published by BCU.", target="_blank"), "Please read the following information 
                    regarding the study carefully before beginning your participation. If you have difficulty accessing 
                    or understanding any part of this information, please contact a member of the research team:", 
                    a(href="mailto:info@harkive.org?subject=Harkive Research Ethics Question: via Shiny app", 
                      "info@harkive.org"), 
                    p(), h4("INFORMED CONSENT"), p(),
                    "You have been invited to take part in a research study that is looking at the experiences of 
                    music listeners. The project has been approved by the Birmingham City University Research Ethics Committee, and your understanding of 
                    the information in this document are a condition of that approval.", p(),
                    h4("ABOUT YOUR PARTICIPATION"), p(),
                    "In this study, you will be posting information in the form of digital text and/or images and 
                    video via a connected device of your choice (e.g. mobile phone, laptop, tablet) to one or more of a 
                    number of online interfaces and platforms.", p(),
                    "In many cases these will be 3rd party-owned platforms and interfaces and will include services such 
                    as", tags$b("Twitter, Facebook, Instagram,"), "and", tags$b("Tumblr."), "By adding the hashtag",
                    tags$i("#harkive"), "to your posts on these services, you will enable this project to harvest your 
                    Harkive stories. Depending on the method you decide to use, and on your privacy settings within 
                    the interfaces of the 3rd-party service concerned, the project may also gather additional information 
                    alongside your text. This additional information may includes time stamps, location data and other data
                    available via the APIs of those 3rd-party services.", p(),
                    "You may also/instead decide to send your Harkive story via the online form available on the Harkive 
                    site or within this app, or by emailing it to,", 
                    a(href="mailto:submit@harkive.org?subject=Harkive 2018 story: via Shiny app", 
                      "submit@harkive.org."), "By contributing your 
                    stories via these methods you will be providing The Harkive Project with additional information 
                    (in particular, your email address). Please be aware that this additional, personal information will 
                    not be made available to 3rd parties without your consent. You should also be aware that, in the 
                    main body of your Harkive story submitted via the form/email, you are advised to exclude any 
                    personal information, and in particular information such as contact/employer information 
                    (e.g. telephone numbers, email/postal addresses) that may appear in automatic email signatures. 
                    The general advice here is that, in much the same way that you would be advised against posting 
                    personal information on to 3rd-Party, publicly available sites, you should exercise similar caution 
                    in your own Harkive story posted via email/the form on the Harkive site.", p(),
                    "You are also invited to complete a short, online survey about your music listening experience. 
                    Participation in this survey is voluntary and is not a pre/post-requisite of participation in the story gathering exercise on 17th July 2018. 
                    The aim of the survey is to provide additional context and information that will assist with the analysis stage of the project. The survey 
                    element of this research project is also requires your informed consent and you will not be able to complete/view the survey without first 
                    indicating consent.", p(),
                    "At some stage after 17th July 2018 you may be invited to take part in follow up interviews. 
                    We envisage that these interviews will include only a very small number of participants. If selected 
                    for interview you will be contacted via email. Participation in this stage of 
                    the project is also voluntary.", p(),
                    "At the end of the process described above your participation will come to an end. Harkive will return again 
                    in 2019, and in subsequent years. Information regarding your informed consent in further instances of the 
                    project will be made available prior to each instance.", p(),
                    h4("PARTICIPANTS' RIGHTS"), p(),
                    "You may decide to stop being a part of this research project at any time without explanation. You also 
                    have the right to ask that any data you have supplied to the project be withdrawn/destroyed. You can do this 
                    by emailing", a(href="mailto:info@harkive.org?subject=Remove Data from Harkive: via Shiny app", 
                                    "info@harkive.org."), "Please be aware, however, that anything posted to third party 
                    sites (e.g. Twitter, Facebook, Tumblr, Instragram) will remain public/available online until such time as you 
                    delete it, or your account. Data and information posted to 3rd party platforms remains subject to the 
                    Terms and Conditions agreements you have with the services concerned, and as such The Harkive Project has no 
                    control over the use of that data by 3rd party service providers.", p(),
                    "If you would like to stop participation, please cease to post information with the #harkive hashtag. 
                    Your decision to withdraw will not influence the nature of your relationship with the researchers or 
                    their institutions either now or in the future.", p(),
                    h4("BENEFITS AND RISKS"), p(),
                    "Although you might not benefit directly, it is hoped that you will enjoy expressing your opinions on 
                    matters related to your music listening activity, that could have potentially useful outcomes for the 
                    study of popular music, or for future iterations of this research project.", p(),
                    "There are no foreseeable risks to health or well-being as a result of participating in this research project. 
                    Participants are reminded, however, that it is their sole responsibility when posting information to 
                    ensure that it is safe to do so.", p(),
                    "Your participation in this study is voluntary and as such there is no provision for financial 
                    reimbursement of any kind. This includes loss, theft or damage to personal equipment (mobile phones, 
                    laptops, tablets) that may be incurred during the course of participation in the project.", p(),
                    h4("CONFIDENTIALITY/ANONYMITY"), p(),
                    "Any personal information collected during the course of your participation will not be provided to 
                    3rd Parties without your consent.", p(),
                    "During any public (online/offline) dissemination activity or collaborative research undertaken by the 
                    research team (including academic papers and presentations, final doctoral thesis, and so on) your personal 
                    information (names, email addresses, location) will be fully anonymised. You should be aware, however, 
                    that the content of anything 
                    originally posted to 3rd party-owned interfaces (e.g. Twitter, Facebook, Instagram, Tumblr etc) may 
                    remain in the public realm and is subject to the Terms and Conditions of your individual accounts with 
                    those services and you are advised to consult the relevant documentation published by your 
                    service providers.", p(),
                    h4("FOR FURTHER INFORMATION"), p(),
                    "More information can be sought at any time by contacting Craig Hamilton directly via",
                    a(href="mailto:info@harkive.org", "info@harkive.org"),  
                    "including information about results of the study. Additional questions concerning ethics can be 
                    directed to Dr Hazel Collie, Research Ethics Committee Convenor, The School of Media, Birmingham 
                    City University.", p()),
           tabPanel("Code and Sample Data", p(), h3(img(src='http://harkive.org/wp-content/uploads/2015/07/CLMIv-GWwAQbeQS-300x300.png', height = 75, width = 75)),
                    p(), h3("Code and Sample Data"), p(), "The process I have developed around the creation of this application can be broken down 
                    into 3 parts: data collection, analysis and visualisation, and Shiny app creation. On this tab I have provided some resources that may enable you to replicate
                    some or all of that process. If you already have some data and results and would like to begin building you own app, skip to the 3rd section", p(),
                    h4("1: Data collection: From multiple sources to a single database."), p(),
                    "In", a(href="http://harkive.org/datcolzap/", "this blog post", target="_blank"), 
                    "I explain the process I have used to collect data for The Harkive Project,  and how collecting it in the manner that I do considerably helps reduce the amount of time 
                    required in organising and cleaning data ahead of analysis. The resulting database created 
                    by this process is organised according to the principles of Tidy Data (Wickham, 2014), principles that are 
                    extremely useful when using the R package as the primary means of data analysis.", p(),
                    "Hopefully you may find this post and the accompanying video useful if you are considering 
                    using social media and/or other digital data in your own research projects.", p(),
                    htmlOutput(outputId = "video1"), p(), p(),
                    h4("2: Text mining, computational analysis, and visualisation"), p(),
                    "In", a(href="http://harkive.org/h17-text-analysis/", "this blog post", target="_blank"), "I provide a quick 
                    overview of some of the methods I used in analysing and visualising the data collected via the method outlined in Step 1. The post was accompanied by a sample data 
                    set, some code, and the walkthrough video, which I've posted below.", p(), "If you would like to perform some analysis of your own 
                    you should be able to replicate the work shown here by adapting the script I’ve provided to your own 
                    datasets", p(), "To replicate the work in this post and video, you will need R and R Studio installed on your
                    computer (there are help videos for", a(href="https://www.youtube.com/watch?v=5ZbjUEg4a1g", "Windows", target="_blank"), 
                    
                    "and", a(href="https://www.youtube.com/watch?v=5rp9bkc68y0", "MAC", target="_blank"), "to walk you though this", "and also the R code script and sample data set I 
                    have provided", a(href="http://harkive.org/wp-content/uploads/2017/07/h17.zip", "here", target="_blank"), p(),
                    htmlOutput(outputId = "video2"), p(), p(),
                    h4("3: Build a Shiny App"), p(), "COMING SOON", p(),
                    "I'm currently working on the final element of this section - more details posted in due course",
                    p()
                    ),
           tabPanel("Contact", p(), h3(img(src='http://harkive.org/wp-content/uploads/2015/07/CLMIv-GWwAQbeQS-300x300.png', height = 75, width = 75)),
                    p(), h3("Contact The Harkive Project"), p(), 
                    "If you would like to know more about the Harkive project you can contact Craig Hamilton directly by emailing",
                    a(href="mailto:info@harkive.org", "info@harkive.org"), p(), "You can find out more about Harkive by visiting the project website", 
                    a(href="http://www.harkive.org", "www.harkive.org", target="_blank"), p(), "You can follow Harkive on Twitter -", a(href="https://www.twitter.com/harkive", "@harkive", target="_blank"),
                    "which is also the quickest and easiest way to ask a question about the project", p(), "You can also follow Harkive on", 
                    a(href="https://www.facebook.com/harkive", "Facebook", target="_blank"), "(and please take a moment to 'like' the page!) - or on", 
                    a(href="https://www.instagram.com/harkive", "Intsagram", target="_blank"), p(), "Whichever method you choose, it would be nice to hear from you."),
           tabPanel("How to Contribute To Harkive 2018", p(), h3(img(src='http://harkive.org/wp-content/uploads/2015/07/CLMIv-GWwAQbeQS-300x300.png', height = 75, width = 75)),
                    p(), h3("How to Contribute To Harkive 2018"), 
                    "There are a number of ways you can contribute to Harkive on 17th July 2018, each of 
                    which are detailed below. You can use each of these methods in isolation, or several in combination.",
                    p(),
                    "If you would like to see some examples of how contributions work via the various methods, please 
                    take a moment to look at the", tags$b("Read the Stories"), "tab, or visit the 
                    project website where we have been posting examples from lots of interesting people.", p(),
                    "You are advised that by submitting Harkive stories via any of the methods below, you are 
                    indicating that you have read and understood our", tags$b("Research Ethics"), "documentation and 
                    are providing your Informed Consent to participate in this study. If you have questions before proceeding, please contact info@harkive.org", p(),
                    h4("Contribute via Email"), p(),
                    "You can email your story to", tags$b("submit@harkive.org"), "You can attached photos, video or audio 
                    files related to your submission to the email message, or you can include links to where these elements 
                    can be accessed. You can write as much, or as little, as you like.", p(),
                    h4("Complete the form on the Harkive site, or in this app"), p(),
                    "You can contribute to Harkive by completing the form on the Harkive site, which you will also find on the",
                    tags$b("Tell your story"), "tab. If you would like to include links to photos, videos or 
                    audio files you can add the links to the body of the text.", p(),
                    h4("Twitter, Instagram, and Tumblr"), p(),
                    "You will be able to contribute to Harkive on 17th July 2018 by posting to social
                    media channels and including the hashtag", tags$b("#harkive."), p(), "You can post as many times as you like on the day of Harkive, 
                    thereby creating a diary of your listening across the whole day. If you wish you can also include 
                    images, links to videos and other digital information in your posts. Harkive will automatically harvest 
                    any posts to Twitter, Tumblr and Instagram with the #harkive hashtag.", p(),
                    h4("Facebook"), p(),
                    "There is a Harkive page over on Facebook. You will need to Like the page in order to contribute 
                    to Harkive, which you can do by posting your story on the page on 17th July 2018.", p(), tags$b("Please note:"),"posts on your own timeline 
                    will NOT be harvested, even if you include the #harkive hashtag.", p(),
                    h4("Your own blog, Wordpress or Medium page"), p(),
                    "You can also contribute your story to Harkive using your own blog. Simply post your long-form 
                    listening observations to your site and include the word harkive in the text somewhere.  
                    Please be aware, however, that this process of story collection is not automated, so if you do 
                    tell your story in this way you we politely request that you also either email or submit the 
                    full text to us. If this is difficult, you can always send us the URL to the story and we can 
                    manually harvest the text.", p()
           ), 
           tabPanel("Further Reading",
                    p(), h3(img(src='http://harkive.org/wp-content/uploads/2015/07/CLMIv-GWwAQbeQS-300x300.png', height = 75, width = 75)), p(), h3("Further Reading"), p(),
                    h4("Published Articles and Chapters"), p(), hr(), p(),
                    "Hamilton, C. (2016).", tags$b("The Harkive Project: 
                                                   Rethinking Music Consumption."), tags$i("Networking Knowledge: 
                                                                                           Journal of the MeCCSA Postgraduate Network, 9(5)"), 
                    "Retrieved from, ", a(href ="https://ojs.meccsa.org.uk/index.php/netknow/article/view/466", 
                                          "https://ojs.meccsa.org.uk/index.php/netknow/article/view/466", target="_blank"),
                    p(), hr(), p(),
                    h4("Blog Posts"),
                    p(), hr(), p(),
                    tags$b("Looking at the Monkey Bars"), "| Blog |", tags$i("The Sociological Review."), "2018. Available at:", 
                    a(href = "https://www.thesociologicalreview.com/blog/looking-at-the-monkey-bars.html", 
                      "https://www.thesociologicalreview.com/blog/looking-at-the-monkey-bars.html", target="_blank"),
                    p(),
                    tags$b("How Do People Listen To Music In 2013? It's A Complex Business"), "| Blog |", tags$i("NME"), "Available at: ",
                    a(href = "http://www.nme.com/blogs/nme-blogs/how-do-people-listen-to-music-in-2013-its-a-complex-business-22998", 
                      "http://www.nme.com/blogs/nme-blogs/how-do-people-listen-to-music-in-2013-its-a-complex-business-22998", target="_blank"),
                    p(), hr(), p(),
                    h4("Bibiography:"),
                    p(), hr(), p(),
                    "Berry, D.M. (2011)", tags$b("The computational turn: Thinking about the digital humanities."), tags$i("Culture Machine, 12."),  
                    p(),
                    "Blei, D.M. (2012)", tags$b("Topic modeling and digital humanities"), tags$i("Journal of Digital Humanities. 2, 8-11"),
                    p(),                  
                    "Blei, D.M., Ng, A.Y. and Jordan, M.I. (2003)", tags$b("Latent dirichlet allocation"), tags$i("Journal of machine Learning research"), 
                    "3(Jan), pp.993-1022",
                    p(),
                    "Hall, G. (2013)", tags$b("Toward a postdigital humanities: Cultural analytics and the computational turn to data-driven scholarship."),  
                    tags$i("American Literature, 85(4)"),
                    p(),
                    "Housley, W., Procter, R., Edwards, A., Burnap, P., Williams, M., Sloan, L., Rana, O., Morgan, J., 
                    Voss, A. and Greenhill, A. (2014)", tags$b("Big and broad social data and the sociological imagination: A collaborative response"), 
                    tags$i("Big Data & Society, 
                           1(2), p.2053951714545135."),
                    p(),
                    "Jockers, M. (2015).", tags$b("Revealing sentiment and plot arcs with the syuzhet package."), "Available at:",
                    a(href="http://www.matthewjockers.net/2015/02/02/syuzhet/","http://www.matthewjockers.net/2015/02/02/syuzhet/", target="_blank"),
                    p(),
                    "Kitchin, R. (2014)", tags$b("Big Data, new epistemologies and paradigm shifts"), tags$i("Big Data & Society"), "1(1).",
                    p(),
                    "Kitchin, R. (2014)", tags$b("The data revolution: Big data, open data, data infrastructures and their consequences."), "Sage.",
                    p(),
                    "Negus, K. (1997)", tags$b("Popular music in theory: An introduction"), tags$i("Wesleyan University Press."),
                    p(),
                    "Swafford, A. (2015)", tags$b("Problems with the syuzhet package"), "Anglophile in Academia: 
                    Annie Swafford's Blog. Available at:", a(href = "https://annieswafford.wordpress.com/2015/03/02/syuzhet/",
                                                             "https://annieswafford.wordpress.com/2015/03/02/syuzhet/", target="_blank"),  
                    p(),
                    "Wickham, H. (2014)", tags$b("Tidy data."), tags$i("Journal of Statistical Software"), "59(10), pp.1-23.",
                    p(),
                    "Zimmer, M. (2010)", tags$b("'But the data is already public': on the ethics of research in Facebook"), "Ethics and 
                    information technology, 12(4), pp.313-325.",
                    p(),
                    "Zimmer, M. (2015)", tags$b("The Twitter Archive at the Library of Congress: Challenges for information 
                                                practice and information policy."), "First Monday, 20(7)", p()
                    )                             
                    )
           )


           )
  )
           )

# Define server function required to create the scatterplot
server <- function(input, output) {
  
  # Create reactive data frame
  story_sample <- reactive({
    req(input$method)
    req(input$year)
    req(input$topic)
    req(input$words)
    req(input$sent_name)
    story_sample <- story %>%
      filter(wordsinstory <= input$words) %>%
      filter(method %in% input$method) %>%
      filter(year %in% input$year) %>%
      filter(top %in% input$topic) %>%
      filter(sent_name %in% input$sent_name)
  })
  
  matrix_sample <- reactive({
    story_sample <- story_sample()
    matrix_nums <- story_sample[ ,1]
    matrix_sample <- matrix %>%
      filter(story_num %in% matrix_nums)
    matrix_sample <- matrix_sample[, -1]
  })
  
  freqword <- reactive({
    story_sample <- story_sample()
    matrix_sample <- matrix_sample()
    freqword <- colSums(matrix_sample)
  })
  
  trend_percents <- reactive({
    req(input$trend_name)
    story_sample <- story_sample()
    spotify <- story_sample %>%
      group_by(year, spotify) %>%
      tally %>%
      group_by(year) %>%
      mutate(pct=(100*n)/sum(n))
    formatcount <- ifelse(spotify$year != "NA", "Spotify") 
    spotify$format <- formatcount
    spotify$truefalse <- spotify$spotify
    spotify$spotify <- NULL
    form <- spotify
    rm(spotify)
    vinyl <- story_sample %>%
      group_by(year, vinyl) %>%
      tally %>%
      group_by(year) %>%
      mutate(pct=(100*n)/sum(n))
    formatcount <- ifelse(vinyl$year != "NA", "Vinyl") 
    vinyl$format <- formatcount
    vinyl$truefalse <- vinyl$vinyl
    vinyl$vinyl <- NULL
    form <- bind_rows(form, vinyl)
    rm(vinyl)
    ipod <- story_sample %>%
      group_by(year, ipod) %>%
      tally %>%
      group_by(year) %>%
      mutate(pct=(100*n)/sum(n))
    formatcount <- ifelse(ipod$year != "NA", "ipod") 
    ipod$format <- formatcount
    ipod$truefalse <- ipod$ipod
    ipod$ipod <- NULL
    form <- bind_rows(form, ipod)
    rm(ipod)
    radio <- story_sample %>%
      group_by(year, radio) %>%
      tally %>%
      group_by(year) %>%
      mutate(pct=(100*n)/sum(n))
    formatcount <- ifelse(radio$year != "NA", "Radio") 
    radio$format <- formatcount
    radio$truefalse <- radio$radio
    radio$radio <- NULL
    form <- bind_rows(form, radio)
    rm(radio)
    stream <- story_sample %>%
      group_by(year, stream) %>%
      tally %>%
      group_by(year) %>%
      mutate(pct=(100*n)/sum(n))
    formatcount <- ifelse(stream$year != "NA", "Stream") 
    stream$format <- formatcount
    stream$truefalse <- stream$stream
    stream$stream <- NULL
    form <- bind_rows(form, stream)
    rm(stream)
    playlist <- story_sample %>%
      group_by(year, playlist) %>%
      tally %>%
      group_by(year) %>%
      mutate(pct=(100*n)/sum(n))
    formatcount <- ifelse(playlist$year != "NA", "Playlist") 
    playlist$format <- formatcount
    playlist$truefalse <- playlist$playlist
    playlist$playlist <- NULL
    form <- bind_rows(form, playlist)
    rm(playlist)
    shuffle <- story_sample %>%
      group_by(year, shuffle) %>%
      tally %>%
      group_by(year) %>%
      mutate(pct=(100*n)/sum(n))
    formatcount <- ifelse(shuffle$year != "NA", "Shuffle") 
    shuffle$format <- formatcount
    shuffle$truefalse <- shuffle$shuffle
    shuffle$shuffle <- NULL
    form <- bind_rows(form, shuffle)
    rm(shuffle)
    youtube <- story_sample %>%
      group_by(year, youtube) %>%
      tally %>%
      group_by(year) %>%
      mutate(pct=(100*n)/sum(n))
    formatcount <- ifelse(youtube$year != "NA", "YouTube") 
    youtube$format <- formatcount
    youtube$truefalse <- youtube$youtube
    youtube$youtube <- NULL
    form <- bind_rows(form, youtube)
    rm(youtube)
    trend_percents <- filter(form, truefalse == "TRUE")
    trend_percents <- trend_percents %>%
      filter(format %in% input$trend_name)
  })
  
  
  #OUTPUT TAB
  output$counting <- renderText({
    story_sample <- story_sample()
    paste0("Your current selection returns ", (nrow(story_sample)), " entries from the database.")
  })  
  
  #WORDFREQUENCY TAB  
  output$wordfrequency <- renderPlot({
    story_sample <- story_sample()
    matrix_sample <- matrix_sample()
    freqword <- freqword()
    wf=data.frame(term=names(freqword),occurrences=freqword)
    ggplot(subset(wf, freqword>input$wordfreq), aes(x = reorder(term, occurrences), y = occurrences, fill = occurrences)) +
      geom_bar(stat="identity") + theme(axis.text.y=element_text(angle=45, hjust=1)) +  
      coord_flip(xlim = NULL, ylim = NULL, expand = TRUE) +
      scale_fill_gradient2(low = "white", mid = "pink", high = "red", limits = c(75, 600)) +
      theme(legend.position = "none") +
      xlab("Words") + ylab("Occurences")
  })
  
  #WORDCLOUD TAB
  #output$wordcloudplot <- renderPlot({
  #  story_sample <- story_sample()
  #  matrix_sample <- matrix_sample()
  #  freqword <- freqword()
  #  set.seed(24)
  #  wordcloud(names(freqword),freqword, scale = c(3,.8), min.freq=input$wordfreq,colors=brewer.pal(5,"Reds"))
  #})
  
  #BARPLOT TAB
  output$barplot <- renderPlot({
    story_sample <- story_sample()
    ggplot(data = story_sample(), aes_string(x = story_sample$year, fill = input$z)) +
      geom_bar(position = "stack", stat = "count") + 
      xlab("Year") + ylab("Number of Stories")
  })  
  
  #####FIX THIS###########FIX THIS############FIX THIS############FIX THIS#######
  
  #SENT v TOPIC  
  #  output$sent_topic <- renderPlot({
  #    story_sample <- story_sample()
  #    ggplot(data = story_sample(), aes(x = sent_by_word, y = sdLDA_K8, fill = input$z)) +
  #      geom_jitter() + xlab("Sentiment") + ylab("SD in Topic Allocation")
  #  })
  #####FIX THIS############FIX THIS############FIX THIS############FIX THIS#######
  
  #READ THE STORIES TAB
  output$storytable <- DT::renderDataTable({
    story_sample <- story_sample()
    DT::datatable(data = story_sample[,c(4, 2:3)], 
                  options = list(pageLength = 5),
                  rownames = FALSE)
  })
  
  #SUBMIT STORY:
  output$submit <- renderUI({
    tags$iframe(width="100%", height = "1300", src="https://docs.google.com/forms/d/e/1FAIpQLSfkJMuwUAQ3vyedlfBPTN_QlAGmcmbmGN-uhgU79NTocmQgPg/viewform?embedded=true", frameborder="0", marginheight="0", marginwidth="0")
  })
  
  #####FIX THIS############FIX THIS############FIX THIS#######
  
  #LISTENING SURVEY
  #output$survey <- renderUI({
  #  tags$iframe(width= "100%", height = "1800", src ="https://form.jotformeu.com/81574556064361", frameborder="0", marginheight="0", marginwidth="0")
  #})
  
  #####FIX THIS############FIX THIS############FIX THIS#######
  
  #VIDEO 1 - DATA COLLECTION
  output$video1 <- renderUI({
    tags$iframe(width= "560", height = "315", src ="https://www.youtube.com/embed/XTvxznGaUdY", frameborder="0", marginheight="0", marginwidth="0")
  })
  
  #VIDEO 2 - ANALYSIS
  output$video2 <- renderUI({
    tags$iframe(width= "560", height = "315", src ="https://www.youtube.com/embed/vdADo3Ryj1E", frameborder="0", marginheight="0", marginwidth="0")
  })
  
  
  #TRENDS
  output$trends <- renderPlot({
    story_sample <- story_sample()
    trend_percents <- trend_percents()
    trend_percents %>%  
      ggplot() +
      aes(year, pct, colour = format) +
      geom_point() +
      geom_line() +
      xlab("Year") + ylab("Percentage") + 
      scale_fill_manual(name="Formats")
  })
  
  #SENTIMENT ANALYSIS TAB BARPLOT
  output$sentplot <- renderPlot({
    story_sample <- story_sample()
    sentimentTotals <- data.frame(colSums(story_sample[,c(17:23)]))
    names(sentimentTotals) <- "count"
    sentimentTotals <- cbind("sentiment" = rownames(sentimentTotals), sentimentTotals)
    rownames(sentimentTotals) <- NULL
    ggplot(data = sentimentTotals, aes(x = sentiment, y = count)) +
      geom_bar(aes(fill = sentiment), stat = "identity") +
      theme(legend.position = "none") +
      xlab("NRC Algorithm Sentiment Categories") + ylab("Total Sentiment Score")
  })  
  
}

# Create a Shiny app object
shinyApp(ui = ui, server = server)