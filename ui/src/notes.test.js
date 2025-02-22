import { describe, expect, test } from '@jest/globals';
import { dom } from './dom.js';
import { config } from "./config";


jest.mock('./request.js', () => (
  {
    get: jest.fn((_router, _url, callback) => callback([{
      noteStart: '2020-10-12T14:30',
      noteView: 'content', noteTags: []
    }], {}))
  }
));

import notes from './notes';
import Navigo from "navigo";

describe('Notes', () => {

  let router;
  let container;

  beforeEach(() => {
    router = new Navigo(null, false);
    container = document.createElement('div');
  });

  test('it should display note date like "2020-10-12"', () => {
    notes.list(router, container, 1);
    expect(container).toMatchSnapshot();
  });
})
