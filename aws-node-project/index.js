const axios = require('axios').default
  
const handler = async (event) => {
  let newevent = JSON.parse(event.Records[0].body)
  console.log(event);
  console.log("event : ", newevent);

  const CallbackUrl = process.env.callback_ENDPOINT
  console.log

  await axios.post('http://project3-factory.coz-devops.click/api/manufactures', {
      "MessageGroupId": 'stock-arrival-group',
      "MessageAttributeProductId": 'CP-502101',
      "MessageAttributeProductCnt": 3,
      "MessageAttributeFactoryId": 'FF-500293',
      "MessageAttributeRequester": 'hansung',
      "CallbackUrl": `${CallbackUrl}/product/donut`
  })
      .then(function (response) {
        console.log("성공");
      })
      .catch(function (error) {
        console.log(error);
  });
}

module.exports = {
  handler,
};