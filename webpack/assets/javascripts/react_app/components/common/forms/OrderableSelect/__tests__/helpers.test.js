import { orderDragged, makeOnHover } from '../helpers';

describe('orderingHelpers', () => {
  describe('orderDragged', () => {
    it('reorders the given element of the array', () => {
      expect(orderDragged([1, 2, 3], 1, 0)).toEqual([2, 1, 3]);
      expect(orderDragged([1, 2, 3], 1, 2)).toEqual([1, 3, 2]);
    });
  });

  describe('hoverHandler', () => {
    let moveFnc;
    let handler;
    let monitor;
    let component;

    const setup = (direction) => {
      const item = { index: 1 };
      const getItem = () => item;
      const getClientOffset = () => ({ x: 34, y: 54 });
      const getBoundingClientRect = jest.fn(() => ({ left: 30, right: 40, top: 50, bottom: 60 }));
      const getIndex = props => props.index;
      const getMoveFnc = props => moveFnc;

      moveFnc = jest.fn();
      handler = makeOnHover(getIndex, getMoveFnc, direction);
      monitor = { getItem, getClientOffset };
      component = { getNode: () => ({ getBoundingClientRect }) };
    }

    describe('horizontal movement', () => {
      beforeEach(() => {
        setup('horizontal')
      });

      it('returns if hovering over dragged item', () => {
        handler({ index: 1 }, monitor, component);
        expect(moveFnc).not.toBeCalled();
        expect(component.getNode().getBoundingClientRect).not.toBeCalled();
      });

      it('returns if hovering over item on left, but not crossed half', () => {
        monitor.getClientOffset = () => ({ x: 38 });
        handler({ index: 0 }, monitor, component);
        expect(component.getNode().getBoundingClientRect).toBeCalled();
        expect(moveFnc).not.toBeCalled();
      });

      it('returns if hovering over item on right, but not crossed half', () => {
        handler({ index: 2 }, monitor, component);
        expect(component.getNode().getBoundingClientRect).toBeCalled();
        expect(moveFnc).not.toBeCalled();
      });

      it('call ordering fnc and sets index of dragged item to target index', () => {
        handler({ index: 0 }, monitor, component);
        expect(moveFnc).toBeCalledWith(1, 0);
        expect(monitor.getItem().index).toEqual(0);
      });
    });

    describe('vertical movement', () => {
      beforeEach(() => {
        setup('vertical')
      });

      it('returns if hovering over dragged item', () => {
        handler({ index: 1 }, monitor, component);
        expect(moveFnc).not.toBeCalled();
        expect(component.getNode().getBoundingClientRect).not.toBeCalled();
      });

      it('returns if hovering over item below, but not crossed half', () => {
        monitor.getClientOffset = () => ({ y: 56 });
        handler({ index: 0 }, monitor, component);
        expect(component.getNode().getBoundingClientRect).toBeCalled();
        expect(moveFnc).not.toBeCalled();
      });

      it('returns if hovering over item on above, but not crossed half', () => {
        handler({ index: 2 }, monitor, component);
        expect(component.getNode().getBoundingClientRect).toBeCalled();
        expect(moveFnc).not.toBeCalled();
      });

      it('call ordering fnc and sets index of dragged item to target index', () => {
        handler({ index: 0 }, monitor, component);
        expect(moveFnc).toBeCalledWith(1, 0);
        expect(monitor.getItem().index).toEqual(0);
      });
    })
  });
});
