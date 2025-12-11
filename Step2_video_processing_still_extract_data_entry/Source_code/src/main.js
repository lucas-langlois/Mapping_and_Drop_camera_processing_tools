console.log("Welcome to My Console App!");

function getUserInput() {
    const readline = require('readline').createInterface({
        input: process.stdin,
        output: process.stdout
    });

    readline.question('Please enter your input: ', (input) => {
        console.log(`You entered: ${input}`);
        readline.close();
    });
}

getUserInput();