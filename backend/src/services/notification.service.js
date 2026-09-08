const userModel = require('../models/user.model');
const smsService = require('./sms.service');

const TEMPLATES = {
  en: {
    bid_received: (p) => `New bid of Rs.${p.amount} received on your batch.`,
    auction_ending_soon: (p) => `Your auction for ${p.cropName} ends in ${p.minutesLeft} min - ${p.bidCount} bid(s) so far, highest Rs.${p.highestBid}.`,
    auction_won: (p) => `Congratulations! You won the bid for ${p.cropName} at Rs.${p.amount}.`,
    sale_confirmed: (p) => `You selected a winning bid for ${p.cropName} at Rs.${p.amount}.`,
    payment_released: (p) => `Payment of Rs.${p.amount} released for batch ${p.cropName} - delivery confirmed.`,
  },
  hi: {
    bid_received: (p) => `Aapke batch par Rs.${p.amount} ki nai bid mili hai.`,
    auction_ending_soon: (p) => `${p.cropName} ki auction ${p.minutesLeft} minute mein khatam ho rahi hai - ${p.bidCount} bid, sabse zyada Rs.${p.highestBid}.`,
    auction_won: (p) => `Badhai ho! Aapne ${p.cropName} ki bid Rs.${p.amount} mein jeet li.`,
    sale_confirmed: (p) => `Aapne ${p.cropName} ke liye Rs.${p.amount} ki bid select ki hai.`,
    payment_released: (p) => `Batch ${p.cropName} ke liye Rs.${p.amount} ka payment release ho gaya - delivery confirm ho gayi.`,
  },
  ta: {
    bid_received: (p) => `Unga batch-ku Rs.${p.amount} pudhu bid kidaichirukku.`,
    auction_ending_soon: (p) => `${p.cropName} auction ${p.minutesLeft} nimidathil mudivadaiyum - ${p.bidCount} bid, athigapatcham Rs.${p.highestBid}.`,
    auction_won: (p) => `Vazhthukkal! Neenga ${p.cropName}-ku Rs.${p.amount} bid-ல வென்றீங்க.`,
    sale_confirmed: (p) => `Neenga ${p.cropName}-ku Rs.${p.amount} bid-a select pannirukeenga.`,
    payment_released: (p) => `Batch ${p.cropName}-ku Rs.${p.amount} payment release aayiduchu - delivery confirm aachu.`,
  },
};

async function send({ userId, templateKey, params = {}, language }) {
  const user = await userModel.findById(userId);
  if (!user) return;

  const lang = language && TEMPLATES[language] ? language : 'en';
  const templateFn = TEMPLATES[lang][templateKey];
  if (!templateFn) return;

  const message = templateFn(params);
  await smsService.sendSms(user.phone, message);
}

module.exports = { send };
