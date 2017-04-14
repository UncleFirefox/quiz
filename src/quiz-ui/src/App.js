import React, { Component } from 'react';
import Loader from './Loader';
import Voting from './Voting';
import Results from './Results';
import { getQuiz, postQuizAnswers, startNewQuiz, initWebsockets } from './api';
import { bindClass } from './utils';

import './App.css';

class App extends Component {
  constructor(props) {
    super(props);
    this.state = {
      quizId: 0,
      questions: [],
      isProcessing: true,
      showResults: false
    };

    bindClass(this);
  }

  componentDidMount() {
    getQuiz().then(json => {
      if (json != null) {
        this.setState({
          quizId: json.quizId,
          questions: json.quizModel.questions.map(q => ({
            ...q,
            ...json.questions.find(x => x.questionId === q.id)
          })),
          isProcessing: false
        });
      } else {
        this.setState({
          isProcessing: false,
          showResults: true
        });
      }
    });

    initWebsockets(questionStats => this.setState({
      ...this.state,
      questions: this.state.questions.map(
        question => question.id === questionStats.questionId
          ? {
              ...question,
              ...questionStats
            }
          : question
      )
    }));
  }

  startQuizHandler() {
    startNewQuiz().then(json => this.setState({
      ...json
    }));
  }

  showResultsHandler() {
    this.setState({
      showResults: true
    });
  }

  showVotingHandler() {
    this.setState({
      showResults: false
    });
  }

  voteQuestionHandler(answers) {
    this.setState({
      isProcessing: true
    });

    postQuizAnswers(this.state.quizId, answers).then(json => {
      this.setState({
        isProcessing: false
      });
    });
  }

  render() {
    const {
      isProcessing,
      showResults,
      questions,
      quizId
    } = this.state;
    return (
      <div className="Container">
        {isProcessing &&
          <div className="overlay">
            <Loader />
          </div>}
        <div className="App-container">
          <div className="App">
            <h1>Welcome to Quiz App</h1>
            {showResults
              ? <Results
                  questions={questions}
                  quizId={quizId}
                  showVotingHandler={this.showVotingHandler}
                  startQuizHandler={this.startQuizHandler}
                />
              : <Voting
                  questions={questions}
                  voteQuestionHandler={this.voteQuestionHandler}
                  showResultsHandler={this.showResultsHandler}
                />}
          </div>
        </div>
      </div>
    );
  }
}

export default App;
