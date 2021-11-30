exports.handler = (event, context, callback) => {
    console.log('Lambda Check');
    callback(null, 'Works');
}